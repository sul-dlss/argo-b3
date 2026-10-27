# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::PurgeService do
  let(:druid) { 'druid:bc123cd4567' }

  describe '.purgeable?' do
    context 'when the object is not submitted' do
      before do
        allow(Sdr::WorkflowService).to receive(:submitted?).with(druid:).and_return(false)
      end

      it 'returns true' do
        expect(described_class.purgeable?(druid:)).to be true
      end
    end

    context 'when the object is submitted' do
      before do
        allow(Sdr::WorkflowService).to receive(:submitted?).with(druid:).and_return(true)
      end

      it 'returns false' do
        expect(described_class.purgeable?(druid:)).to be false
      end
    end

    context 'when the version is the first version' do
      before do
        allow(Sdr::WorkflowService).to receive(:submitted?).with(druid:).and_return(false)
      end

      it 'checks whether the object is submitted' do
        expect(described_class.purgeable?(druid:, version: 1)).to be true
        expect(Sdr::WorkflowService).to have_received(:submitted?).with(druid:)
      end
    end

    context 'when the version is a later version' do
      before do
        allow(Sdr::WorkflowService).to receive(:submitted?)
      end

      it 'returns false without checking whether the object is submitted' do
        expect(described_class.purgeable?(druid:, version: 2)).to be false
        expect(Sdr::WorkflowService).not_to have_received(:submitted?)
      end
    end
  end

  describe '.purge' do
    let(:user_name) { 'testuser' }

    let(:object_client) { instance_double(Dor::Services::Client::Object, destroy: nil) }

    context 'when the object can be purged' do
      let(:staged_filepaths) do
        StagingSupport.locations.map do |staging_location|
          StagingSupport.staging_filepath(druid:, filepath: 'folder1/image1.tif', staging_location:)
        end
      end
      let!(:content) { create(:content, :mutable, druid:) }
      let!(:immutable_content) { create(:content, druid:) }

      before do
        allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
        allow(Sdr::WorkflowService).to receive(:submitted?).with(druid:).and_return(false)
        staged_filepaths.each do |staged_filepath|
          FileUtils.mkdir_p(File.dirname(staged_filepath))
          FileUtils.touch(staged_filepath)
        end
      end

      after do
        StagingSupport.delete_staged_files(druid:)
      end

      it 'performs purge and deletes the mutable content and staged files' do
        described_class.purge(druid:, user_name:)
        expect(object_client).to have_received(:destroy).with(user_name:)
        expect(Content.exists?(content.id)).to be false
        expect(Content.exists?(immutable_content.id)).to be true
        expect(StagingSupport.staged_files?(druid:)).to be false
      end
    end

    context 'when the object client fails' do
      let!(:content) { create(:content, :mutable, druid:) }

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
        allow(Sdr::WorkflowService).to receive(:submitted?).and_return(false)
        allow(object_client).to receive(:destroy).and_raise(Dor::Services::Client::Error, 'Oops')
      end

      it 'raises a purge service error without deleting the mutable content' do
        expect { described_class.purge(druid:, user_name:) }
          .to raise_error(Sdr::PurgeService::Error, 'Purging failed: Oops')
        expect(Content.exists?(content.id)).to be true
      end
    end

    context 'when a content for the object is staging' do
      let!(:content) { create(:content, druid:, staging_state: 'staging') }

      before do
        allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
        allow(Sdr::WorkflowService).to receive(:submitted?).with(druid:).and_return(false)
      end

      it 'raises ContentBusyError without purging' do
        expect { described_class.purge(druid:, user_name:) }.to raise_error(Sdr::PurgeService::ContentBusyError)

        expect(object_client).not_to have_received(:destroy)
        expect(Content.exists?(content.id)).to be true
      end
    end

    context 'when a content for the object is discovering' do
      before do
        create(:content, :mutable, druid:, mount_state: 'discovering')
        allow(Sdr::WorkflowService).to receive(:submitted?).with(druid:).and_return(false)
      end

      it 'raises ContentBusyError' do
        expect { described_class.purge(druid:, user_name:) }.to raise_error(Sdr::PurgeService::ContentBusyError)
      end
    end

    context 'when the object cannot be purged' do
      before do
        allow(Sdr::WorkflowService).to receive(:submitted?).with(druid:).and_return(true)
      end

      it 'raises CannotPurgeError' do
        expect { described_class.purge(druid:, user_name:) }.to raise_error(Sdr::PurgeService::CannotPurgeError)
      end
    end
  end
end
