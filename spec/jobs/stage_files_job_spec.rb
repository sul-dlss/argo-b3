# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StageFilesJob do
  subject(:job) { described_class.new }

  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:content) { create(:content, druid:, lock: 'druid-version-1', staging_state: 'staging') }
  let(:cocina_object) { instance_double(Cocina::Models::DROWithMetadata, lock: 'druid-version-1') }
  let(:updated_cocina_object) { instance_double(Cocina::Models::DROWithMetadata, lock: 'druid-version-2') }
  let(:mutated_cocina_object) { instance_double(Cocina::Models::DRO) }

  let(:attached_content_file_binary) do
    create(:content_file_binary, content:, file_location: 'attached', filepath: 'image1.tif')
  end
  let(:deposited_content_file_binary) do
    create(:content_file_binary, content:, file_location: 'deposited', filepath: 'image2.tif')
  end

  let(:staging_filepath) { StagingSupport.staging_filepath(druid:, filepath: 'image1.tif') }

  before do
    attached_content_file_binary.file.attach(fixture_file_upload('dropzone_upload.txt', 'text/plain'))
    deposited_content_file_binary

    allow(Contents::Analyzer).to receive(:call)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(CocinaObjectMutators::StructuralMutator).to receive(:call)
      .with(cocina_object:, content:).and_return(mutated_cocina_object)
    allow(Sdr::Repository).to receive(:update)
      .with(cocina_object: mutated_cocina_object, user_name: user.sunetid).and_return(updated_cocina_object)
    allow(Sdr::Repository).to receive(:accession)
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
  end

  after do
    FileUtils.rm_rf(StagingSupport.staging_content_path(druid:))
  end

  describe '#perform' do
    it 'analyzes only the attached content file binaries' do
      job.perform(content:, user:)

      expect(Contents::Analyzer).to have_received(:call).with(content_file_binary: attached_content_file_binary)
      expect(Contents::Analyzer).not_to have_received(:call).with(content_file_binary: deposited_content_file_binary)
    end

    it 'stages only the attached content file binaries' do
      job.perform(content:, user:)

      expect(File.binread(staging_filepath)).to eq(attached_content_file_binary.file.download)
      expect(File.exist?(StagingSupport.staging_filepath(druid:, filepath: 'image2.tif'))).to be false
    end

    it 'updates SDR with the mutated structural metadata' do
      job.perform(content:, user:)

      expect(Sdr::Repository).to have_received(:update)
        .with(cocina_object: mutated_cocina_object, user_name: user.sunetid)
    end

    it "updates the content's lock and marks it immutable" do
      job.perform(content:, user:)

      expect(content.reload).to have_attributes(lock: 'druid-version-2', immutable: true)
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

    it 'does not accession the object' do
      job.perform(content:, user:)

      expect(Sdr::Repository).not_to have_received(:accession)
    end

    context 'when accession is requested' do
      it 'accessions the object' do
        job.perform(content:, user:, accession: true)

        expect(Sdr::Repository).to have_received(:accession).with(druid:, user_name: user.sunetid)
      end
    end

    context "when the content's lock does not match the current cocina object's lock" do
      let(:content) { create(:content, druid:, lock: 'stale-lock', staging_state: 'staging') }

      it 'raises without analyzing, staging, or updating SDR' do
        expect { job.perform(content:, user:) }.to raise_error(/Lock mismatch for #{druid}/)

        expect(Contents::Analyzer).not_to have_received(:call)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(File.exist?(staging_filepath)).to be false
      end
    end
  end
end
