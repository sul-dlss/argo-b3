# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Content do
  let(:druid) { 'druid:bc123df4567' }

  describe '.mutable_for' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid).new(lock: 'current-lock') }
    let!(:mutable_content) { create(:content, :mutable, druid:, lock: 'current-lock') }

    before do
      create(:content, druid:, lock: 'current-lock', immutable: true)
      create(:content, :mutable, druid:, lock: 'old-lock')
      create(:content, :mutable, druid: 'druid:dj123df4598', lock: 'current-lock')
    end

    it 'returns the mutable Content for the lock of the object' do
      expect(described_class.mutable_for(cocina_object)).to eq(mutable_content)
    end
  end

  describe 'staging state' do
    it 'can start staging again after failing staging' do
      content = create(:content, staging_state: 'staging_failed')

      content.staging_started!

      expect(content.reload.staging_state).to eq('staging')
    end

    it 'fails staging from staging' do
      content = create(:content, staging_state: 'staging')

      content.staging_errored!

      expect(content.reload.staging_state).to eq('staging_failed')
    end

    it 'clears a staging failure' do
      content = create(:content, staging_state: 'staging_failed')

      content.staging_failure_cleared!

      expect(content.reload.staging_state).to eq('staging_not_in_progress')
    end
  end

  describe '.latest_staging_activity' do
    before do
      create(:content, druid:, lock: 'lock-1', staging_state: 'staging_not_in_progress', updated_at: 1.minute.ago)
      create(:content, druid: 'druid:df123bc4589', lock: 'lock-1', staging_state: 'staging')
    end

    context 'when no content for the druid is staging or failed staging' do
      it 'returns nil' do
        expect(described_class.latest_staging_activity(druid:)).to be_nil
      end
    end

    context 'when content for the druid is staging, regardless of lock or immutability' do
      let!(:staging_content) do
        create(:content, druid:, lock: 'lock-2', immutable: true, staging_state: 'staging', updated_at: 2.minutes.ago)
      end

      it 'returns the staging content' do
        expect(described_class.latest_staging_activity(druid:)).to eq(staging_content)
      end
    end

    context 'when multiple contents for the druid are staging or failed staging' do
      let!(:latest_content) do
        create(:content, :mutable, druid:, lock: 'lock-3', staging_state: 'staging_failed',
                                   updated_at: 1.minute.ago)
      end

      before do
        create(:content, druid:, lock: 'lock-2', staging_state: 'staging', updated_at: 2.minutes.ago)
      end

      it 'returns the most recently updated' do
        expect(described_class.latest_staging_activity(druid:)).to eq(latest_content)
      end
    end
  end

  describe '.delete_mutable_and_staged_files' do
    let(:staged_filepath) do
      StagingSupport.staging_filepath(druid:, filepath: 'folder1/image1.tif',
                                      staging_location: StagingSupport.locations.first)
    end
    let!(:mutable_content) { create(:content, :mutable, druid:) }
    let!(:immutable_content) { create(:content, druid:) }
    let!(:other_object_mutable_content) { create(:content, :mutable, druid: 'druid:df123bc4589') }

    before do
      FileUtils.mkdir_p(File.dirname(staged_filepath))
      FileUtils.touch(staged_filepath)
    end

    after do
      StagingSupport.delete_staged_files(druid:)
    end

    it 'deletes the mutable contents and staged files for the druid only' do
      described_class.delete_mutable_and_staged_files(druid:)

      expect(described_class.exists?(mutable_content.id)).to be false
      expect(described_class.exists?(immutable_content.id)).to be true
      expect(described_class.exists?(other_object_mutable_content.id)).to be true
      expect(StagingSupport.staged_files?(druid:)).to be false
    end

    context 'when deleting fails' do
      before do
        allow(described_class).to receive(:where).and_raise(ActiveRecord::ActiveRecordError)
        allow(Honeybadger).to receive(:notify)
      end

      it 'notifies without raising' do
        expect { described_class.delete_mutable_and_staged_files(druid:) }.not_to raise_error

        expect(Honeybadger).to have_received(:notify).with(ActiveRecord::ActiveRecordError, context: { druid: })
      end
    end
  end

  describe '#workflow_context' do
    context 'when performing OCR' do
      subject(:content) { build(:content, perform_ocr: true, ocr_languages: %w[English Spanish]) }

      it 'requests OCR in the languages' do
        expect(content.workflow_context).to eq({ runOCR: true, ocrLanguages: %w[English Spanish] })
      end
    end

    context 'when not performing OCR' do
      subject(:content) { build(:content, perform_ocr: false) }

      it 'is empty' do
        expect(content.workflow_context).to eq({})
      end
    end
  end

  describe '#hierarchical_filepaths?' do
    let(:content) { create(:content, druid: 'druid:bc123df4567') }

    before do
      create(:content_file_binary, content:, filepath: 'file1.pdf')
    end

    context 'when a binary has a hierarchical filepath' do
      before do
        create(:content_file_binary, content:, filepath: 'folder1/file2.pdf')
      end

      it 'is true' do
        expect(content.hierarchical_filepaths?).to be true
      end
    end

    context 'when no binary has a hierarchical filepath' do
      it 'is false' do
        expect(content.hierarchical_filepaths?).to be false
      end
    end

    it 'memoizes the result' do
      content.hierarchical_filepaths?
      create(:content_file_binary, content:, filepath: 'folder1/file2.pdf')

      expect(content.hierarchical_filepaths?).to be false
    end
  end

  describe '#staging_or_discovering?' do
    it 'is true only while staging or discovering' do
      expect(build(:content, staging_state: 'staging')).to be_staging_or_discovering
      expect(build(:content, mount_state: 'discovering')).to be_staging_or_discovering
      expect(build(:content, staging_state: 'staging_failed')).not_to be_staging_or_discovering
    end
  end

  describe '#start_staging!' do
    subject(:content) { create(:content, druid:, lock: 'lock-2', staging_state: 'staging_failed') }

    let(:user) { create(:user) }
    let!(:other_failed_content) { create(:content, druid:, lock: 'lock-1', staging_state: 'staging_failed') }
    let!(:other_object_failed_content) do
      create(:content, druid: 'druid:df123bc4589', lock: 'lock-1', staging_state: 'staging_failed')
    end

    before do
      allow(StageFilesJob).to receive(:perform_later)
    end

    it 'starts staging the content with the options' do
      content.start_staging!(user:, accession: true)

      expect(content.reload.staging_state).to eq('staging')
      expect(StageFilesJob).to have_received(:perform_later).with(content:, user:, accession: true)
    end

    it 'clears staging failures for other contents for the druid only' do
      content.start_staging!(user:)

      expect(other_failed_content.reload.staging_state).to eq('staging_not_in_progress')
      expect(other_object_failed_content.reload.staging_state).to eq('staging_failed')
    end
  end
end
