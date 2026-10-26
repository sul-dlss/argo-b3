# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StageFilesJob do
  subject(:job) { described_class.new }

  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:content) { create(:content, :mutable, druid:, lock: 'druid-version-1', staging_state: 'staging') }
  let(:cocina_object) { instance_double(Cocina::Models::DROWithMetadata, lock: 'druid-version-1') }
  let(:updated_cocina_object) { instance_double(Cocina::Models::DROWithMetadata, lock: 'druid-version-2') }
  let(:mutated_cocina_object) { instance_double(Cocina::Models::DRO) }

  let(:attached_content_file_binary) do
    create(:content_file_binary, content:, file_location: 'attached', filepath: 'image1.tif')
  end
  let(:deposited_content_file_binary) do
    create(:content_file_binary, content:, file_location: 'deposited', filepath: 'image2.tif')
  end
  let(:mount_content_file_binary) do
    create(:content_file_binary, content:, file_location: 'mount', mount_path: file_fixture_path,
                                 filepath: 'catalog_record_id_and_barcode.xlsx')
  end

  let(:content_file_set) { create(:content_file_set, content:) }

  let(:staging_filepath) { staged_filepath('image1.tif') }

  def staged_filepath(filepath, staging_location: Settings.staging_location)
    File.join(staging_location, 'bc/123/df/4567/bc123df4567/content', filepath)
  end

  before do
    attached_content_file_binary.file.attach(fixture_file_upload('dropzone_upload.txt', 'text/plain'))
    create(:content_file, content_file_set:, content_file_binary: attached_content_file_binary, position: 1)
    create(:content_file, content_file_set:, content_file_binary: deposited_content_file_binary, position: 2)
    create(:content_file, content_file_set:, content_file_binary: mount_content_file_binary, position: 3)

    allow(Contents::ExternalIdentifierMinter).to receive(:call)
    allow(Contents::Analyzer).to receive(:call)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(CocinaObjectMutators::StructuralMutator).to receive(:call)
      .with(cocina_object:, content:).and_return(mutated_cocina_object)
    allow(Sdr::Repository).to receive(:update)
      .with(cocina_object: mutated_cocina_object, user_name: user.sunetid).and_return(updated_cocina_object)
    allow(Sdr::Repository).to receive(:accession)
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
    allow(Turbo::StreamsChannel).to receive(:broadcast_refresh_to)
  end

  after do
    StagingSupport.locations.each do |staging_location|
      FileUtils.rm_rf(StagingSupport.staging_content_path(druid:, staging_location:))
    end
  end

  describe '#perform' do
    it 'mints external identifiers for the content' do
      job.perform(content:, user:)

      expect(Contents::ExternalIdentifierMinter).to have_received(:call).with(content:)
    end

    it 'sets the Honeybadger context' do
      allow(Honeybadger).to receive(:context)

      job.perform(content:, user:)

      expect(Honeybadger).to have_received(:context)
        .with(content: content.id, druid:, staging_location: Settings.staging_location)
    end

    it 'analyzes only the attached and mount content file binaries' do
      job.perform(content:, user:)

      expect(Contents::Analyzer).to have_received(:call).with(content_file_binary: attached_content_file_binary)
      expect(Contents::Analyzer).to have_received(:call).with(content_file_binary: mount_content_file_binary)
      expect(Contents::Analyzer).not_to have_received(:call).with(content_file_binary: deposited_content_file_binary)
    end

    it 'stages only the attached and mount content file binaries' do
      job.perform(content:, user:)

      expect(File.binread(staging_filepath)).to eq(attached_content_file_binary.file.download)
      expect(File.binread(staged_filepath('catalog_record_id_and_barcode.xlsx')))
        .to eq(file_fixture('catalog_record_id_and_barcode.xlsx').binread)
      expect(File.exist?(staged_filepath('image2.tif'))).to be false
    end

    it 'updates the file location of staged content file binaries to stage' do
      job.perform(content:, user:)

      expect(attached_content_file_binary.reload.file_location).to eq('stage')
      expect(mount_content_file_binary.reload.file_location).to eq('stage')
      expect(deposited_content_file_binary.reload.file_location).to eq('deposited')
    end

    context 'when an attached content file binary is not associated with a content file' do
      let!(:unassociated_content_file_binary) do
        create(:content_file_binary, content:, file_location: 'attached', filepath: 'image3.tif')
      end

      it 'does not analyze or stage it' do
        job.perform(content:, user:)

        expect(Contents::Analyzer).not_to have_received(:call)
          .with(content_file_binary: unassociated_content_file_binary)
        expect(File.exist?(staged_filepath('image3.tif'))).to be false
        expect(unassociated_content_file_binary.reload.file_location).to eq('attached')
      end
    end

    context 'when a content file binary is referenced by multiple content files' do
      before do
        other_content_file_set = create(:content_file_set, content:, position: 2)
        create(:content_file, content_file_set: other_content_file_set,
                              content_file_binary: attached_content_file_binary)
      end

      it 'analyzes and stages it once' do
        job.perform(content:, user:)

        expect(Contents::Analyzer).to have_received(:call)
          .with(content_file_binary: attached_content_file_binary).once
      end
    end

    it 'updates SDR with the mutated structural metadata' do
      job.perform(content:, user:)

      expect(Sdr::Repository).to have_received(:update)
        .with(cocina_object: mutated_cocina_object, user_name: user.sunetid)
    end

    it "updates the content's lock and keeps it mutable" do
      job.perform(content:, user:)

      expect(content.reload).to have_attributes(lock: 'druid-version-2', immutable: false)
    end

    it 'transitions the content out of the staging state' do
      job.perform(content:, user:)

      expect(content.reload.staging_state).to eq('staging_not_in_progress')
    end

    it 'broadcasts a toast notification' do
      job.perform(content:, user:)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
        .with('notifications', user, target: 'toast-container', html: kind_of(String))
    end

    it 'broadcasts a refresh to the object' do
      job.perform(content:, user:)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_refresh_to).with('objects', druid)
    end

    context 'when notifying is not requested' do
      it 'broadcasts a refresh to the object without a toast notification' do
        job.perform(content:, user:, notify: false)

        expect(Turbo::StreamsChannel).to have_received(:broadcast_refresh_to).with('objects', druid)
        expect(Turbo::StreamsChannel).not_to have_received(:broadcast_append_to)
      end
    end

    context 'when another staging location is requested' do
      it 'stages to that location' do
        job.perform(content:, user:, staging_location: Settings.assembly_location)

        expect(File.binread(staged_filepath('image1.tif', staging_location: Settings.assembly_location)))
          .to eq(attached_content_file_binary.file.download)
        expect(File.exist?(staging_filepath)).to be false
      end
    end

    context 'when files are already staged in another staging location' do
      let(:previously_staged_filepath) { staged_filepath('previous.tif') }

      before do
        FileUtils.mkdir_p(File.dirname(previously_staged_filepath))
        FileUtils.touch(previously_staged_filepath)
      end

      it 'stages to the location with the staged files, so that the files are not split' do
        job.perform(content:, user:, staging_location: Settings.assembly_location)

        expect(File.binread(staging_filepath)).to eq(attached_content_file_binary.file.download)
        expect(File.exist?(staged_filepath('image1.tif', staging_location: Settings.assembly_location))).to be false
      end
    end

    it 'does not accession the object' do
      job.perform(content:, user:)

      expect(Sdr::Repository).not_to have_received(:accession)
    end

    context 'when accession is requested' do
      it 'accessions the object' do
        job.perform(content:, user:, accession: true)

        expect(Sdr::Repository).to have_received(:accession).with(cocina_object: updated_cocina_object,
                                                                  user_name: user.sunetid, context: {})
      end

      it "updates the content's lock and marks it immutable" do
        job.perform(content:, user:, accession: true)

        expect(content.reload).to have_attributes(lock: 'druid-version-2', immutable: true)
      end

      context 'with OCR settings' do
        let(:content) do
          create(:content, :mutable, druid:, lock: 'druid-version-1', staging_state: 'staging',
                                     perform_ocr: true, ocr_languages: ['English'])
        end

        it 'passes them on to accessioning' do
          job.perform(content:, user:, accession: true)

          expect(Sdr::Repository).to have_received(:accession)
            .with(cocina_object: updated_cocina_object, user_name: user.sunetid,
                  context: { runOCR: true, ocrLanguages: ['English'] })
        end
      end
    end

    context "when the content's lock does not match the current cocina object's lock" do
      let(:content) { create(:content, :mutable, druid:, lock: 'stale-lock', staging_state: 'staging') }

      it 'does not mint identifiers, analyze, stage, or update SDR' do
        job.perform(content:, user:)

        expect(Contents::ExternalIdentifierMinter).not_to have_received(:call)
        expect(Contents::Analyzer).not_to have_received(:call)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(File.exist?(staging_filepath)).to be false
        expect(content.reload.staging_state).to eq('staging_failed')
      end
    end

    context 'when updating SDR does not change the lock' do
      # The structure is unchanged, so an immutable Content for the lock may already exist.
      let(:updated_cocina_object) { instance_double(Cocina::Models::DROWithMetadata, lock: 'druid-version-1') }
      let!(:existing_content) { create(:content, druid:, lock: 'druid-version-1', immutable: true) }

      it 'replaces the existing immutable content' do
        job.perform(content:, user:, accession: true)

        expect(Content.exists?(existing_content.id)).to be false
        expect(content.reload).to have_attributes(staging_state: 'staging_not_in_progress', lock: 'druid-version-1',
                                                  immutable: true)
        expect(Sdr::Repository).to have_received(:accession)
      end
    end

    context "when updating the content's lock fails" do
      let(:error) { ActiveRecord::RecordInvalid.new(content) }

      before do
        allow(content).to receive(:update!) do |attributes|
          content.assign_attributes(attributes)
          raise error
        end
        allow(Honeybadger).to receive(:notify)
      end

      it 'marks the content as failed staging without the unsaved changes or accessioning' do
        job.perform(content:, user:, accession: true)

        expect(content.reload).to have_attributes(staging_state: 'staging_failed', lock: 'druid-version-1',
                                                  immutable: false)
        expect(Sdr::Repository).not_to have_received(:accession)
        expect(Honeybadger).to have_received(:notify).with(error)
      end
    end

    context 'when making the content immutable fails' do
      let(:error) { ActiveRecord::RecordInvalid.new(content) }

      before do
        allow(content).to receive(:update!).and_wrap_original do |original, attributes|
          next original.call(attributes) unless attributes[:immutable]

          content.assign_attributes(attributes)
          raise error
        end
        allow(Honeybadger).to receive(:notify)
      end

      it 'marks the content as failed staging, keeping it mutable on the new lock' do
        job.perform(content:, user:, accession: true)

        expect(Sdr::Repository).to have_received(:accession)
        expect(content.reload).to have_attributes(staging_state: 'staging_failed', lock: 'druid-version-2',
                                                  immutable: false)
      end
    end

    context 'when accessioning fails' do
      let(:error) { Sdr::Repository::Error.new('Initiating accession failed') }

      before do
        allow(Sdr::Repository).to receive(:accession).and_raise(error)
        allow(Honeybadger).to receive(:notify)
      end

      it 'marks the content as failed staging, keeping it mutable on the new lock' do
        job.perform(content:, user:, accession: true)

        expect(content.reload).to have_attributes(staging_state: 'staging_failed', lock: 'druid-version-2',
                                                  immutable: false)
      end

      it 'notifies Honeybadger' do
        job.perform(content:, user:, accession: true)

        expect(Honeybadger).to have_received(:notify).with(error)
      end

      it 'broadcasts a refresh to the object' do
        job.perform(content:, user:, accession: true)

        expect(Turbo::StreamsChannel).to have_received(:broadcast_refresh_to).with('objects', druid)
      end

      it 'broadcasts an error toast with the support email' do
        job.perform(content:, user:, accession: true)

        expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
          .with('notifications', user, target: 'toast-container',
                                       html: a_string_including('Staging failed', Settings.support_email,
                                                                'bg-stanford-digital-red'))
      end

      context 'when notifying is not requested' do
        it 'does not broadcast an error toast' do
          job.perform(content:, user:, accession: true, notify: false)

          expect(Turbo::StreamsChannel).to have_received(:broadcast_refresh_to).with('objects', druid)
          expect(Turbo::StreamsChannel).not_to have_received(:broadcast_append_to)
        end
      end
    end
  end
end
