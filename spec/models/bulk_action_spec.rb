# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkAction do
  let(:user) { create(:user) }

  describe '.bulk_action_config' do
    subject(:bulk_action) { described_class.new(action_type: :reindex) }

    it 'returns the correct config for the action type' do
      expect(bulk_action.bulk_action_config).to eq(BulkActions::REINDEX)
    end
  end

  describe '.enqueue_job' do
    subject(:bulk_action) { described_class.create!(action_type: :reindex, user:) }

    let(:druids) { ['druid:ab123cd4567', 'druid:ef789gh0123'] }

    it 'enqueues the correct job and updates status to queued' do
      expect do
        bulk_action.enqueue_job(druids:)
      end.to have_enqueued_job(BulkActions::ReindexJob).with(bulk_action:, druids:)

      expect(bulk_action.status).to eq('queued')
    end
  end

  describe '.reset_druid_counts!' do
    subject(:bulk_action) do
      described_class.create!(
        action_type: :reindex,
        user:,
        druid_count_success: 5,
        druid_count_fail: 3,
        druid_count_total: 8
      )
    end

    it 'resets the druid count fields to zero' do
      expect { bulk_action.reset_druid_counts! }.to change {
        [bulk_action.reload.druid_count_success,
         bulk_action.druid_count_fail,
         bulk_action.druid_count_total]
      }.from([5, 3, 8]).to([0, 0, 0])
    end
  end

  describe '.open_log_file' do
    subject(:bulk_action) { described_class.create!(action_type: :reindex, user:) }

    it 'opens the log file for appending' do
      bulk_action.open_log_file do |file|
        expect(file).to be_a(File)
        expect(file.path).to eq(bulk_action.log_filepath)
      end
    end
  end

  describe '.remove_output_directory!' do
    subject(:bulk_action) { described_class.create!(action_type: :reindex, user:) }

    it 'removes the output directory' do
      expect(Dir.exist?(bulk_action.output_directory)).to be true

      bulk_action.remove_output_directory!

      expect(Dir.exist?(bulk_action.output_directory)).to be false
    end
  end

  describe 'creating and removing output directory' do
    subject(:bulk_action) { described_class.create!(action_type: :reindex, user:) }

    it 'creates the output directory and log file on create and removes it on destroy' do
      expect(Dir.exist?(bulk_action.output_directory)).to be true
      expect(File.exist?(bulk_action.log_filepath)).to be true

      bulk_action.destroy

      expect(Dir.exist?(bulk_action.output_directory)).to be false
    end
  end
end
