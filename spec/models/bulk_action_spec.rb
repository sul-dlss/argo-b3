# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkAction do
  let(:user) { create(:user) }

  describe '.bulk_action_config' do
    subject(:bulk_action) { described_class.new(action_type: :reindex) }

    it 'returns the correct config for the action type' do
      expect(bulk_action.bulk_action_config).to eq(BulkActions::REINDEX)
    end

    context 'when the action type is no longer configured' do
      subject(:bulk_action) { described_class.new(action_type: 'OPEN_VERSION') }

      it 'returns a config with a label derived from the action type' do
        expect(bulk_action.label).to eq('Open version')
        expect(bulk_action.exports).to eq([])
      end
    end
  end

  describe '.filtered' do
    let!(:redeposit_processing_bulk_action) { create(:bulk_action, action_type: 'REDEPOSIT', created_at: 3.days.ago) }
    let!(:redeposit_completed_bulk_action) do
      create(:bulk_action, action_type: 'REDEPOSIT', status: :completed, created_at: 10.days.ago)
    end
    let!(:reindex_completed_bulk_action) { create(:bulk_action, action_type: 'REINDEX', status: :completed) }

    it 'returns all bulk actions when there are no filters' do
      expect(described_class.filtered).to contain_exactly(redeposit_processing_bulk_action,
                                                          redeposit_completed_bulk_action,
                                                          reindex_completed_bulk_action)
    end

    it 'returns the bulk actions with the action types and statuses' do
      expect(described_class.filtered(action_types: ['REDEPOSIT'], statuses: ['completed']))
        .to contain_exactly(redeposit_completed_bulk_action)
    end

    it 'returns the bulk actions of the users' do
      expect(described_class.filtered(user_ids: [reindex_completed_bulk_action.user_id.to_s]))
        .to contain_exactly(reindex_completed_bulk_action)
    end

    it 'returns the bulk actions submitted since the time' do
      expect(described_class.filtered(action_types: ['REDEPOSIT'], submitted_since: 7.days.ago))
        .to contain_exactly(redeposit_processing_bulk_action)
    end
  end

  describe '.with_filter_statuses' do
    let!(:created_bulk_action) { create(:bulk_action, status: :created) }
    let!(:started_bulk_action) { create(:bulk_action, status: :started) }
    let!(:completed_bulk_action) { create(:bulk_action, status: :completed, druid_count_fail: 0) }
    let!(:completed_with_errors_bulk_action) { create(:bulk_action, status: :completed, druid_count_fail: 2) }

    it 'returns the bulk actions that are processing' do
      expect(described_class.with_filter_statuses(['processing']))
        .to contain_exactly(created_bulk_action, started_bulk_action)
    end

    it 'returns the bulk actions that completed with and without errors' do
      expect(described_class.with_filter_statuses(['completed'])).to contain_exactly(completed_bulk_action)
      expect(described_class.with_filter_statuses(['completed_with_errors']))
        .to contain_exactly(completed_with_errors_bulk_action)
    end

    it 'returns the bulk actions with any of the display statuses' do
      expect(described_class.with_filter_statuses(%w[processing completed_with_errors]))
        .to contain_exactly(created_bulk_action, started_bulk_action, completed_with_errors_bulk_action)
    end

    it 'returns no bulk actions when there are no known display statuses' do
      expect(described_class.with_filter_statuses(['unknown'])).to be_empty
    end
  end

  describe '.display_status' do
    it 'returns the display status' do
      expect(described_class.new(status: :queued).display_status).to eq('processing')
      expect(described_class.new(status: :completed, druid_count_fail: 0).display_status).to eq('completed')
      expect(described_class.new(status: :completed, druid_count_fail: 1).display_status)
        .to eq('completed_with_errors')
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

  describe '.remove_output_directory!' do
    subject(:bulk_action) { described_class.create!(action_type: :reindex, user:) }

    it 'removes the output directory' do
      expect(Dir.exist?(bulk_action.output_directory)).to be true

      bulk_action.remove_output_directory!

      expect(Dir.exist?(bulk_action.output_directory)).to be false
    end
  end

  describe '.log_filepath' do
    subject(:bulk_action) { described_class.create!(action_type: :reindex, user:) }

    it 'returns the correct log file path' do
      expect(bulk_action.log_filepath)
        .to eq(File.join(Settings.bulk_actions.directory, "reindex_#{bulk_action.id}", 'log.txt'))
    end
  end

  describe '.log_file?' do
    subject(:bulk_action) { described_class.create!(action_type: :reindex, user:) }

    context 'when the log file exists' do
      before do
        File.write(bulk_action.log_filepath, 'Log content')
      end

      it 'returns true' do
        expect(bulk_action.log_file?).to be true
      end
    end

    context 'when the log file does not exist' do
      it 'returns false' do
        expect(bulk_action.log_file?).to be false
      end
    end
  end

  describe '.export_filepath' do
    subject(:bulk_action) { described_class.create!(action_type: :export_cocina_json, user:) }

    it 'returns the export file path for the key' do
      expect(bulk_action.export_filepath(:cocina_json))
        .to eq(File.join(Settings.bulk_actions.directory, "export_cocina_json_#{bulk_action.id}", 'cocina.jsonl.gz'))
    end

    context 'when the key is not configured' do
      it 'raises' do
        expect { bulk_action.export_filepath(:tags) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.existing_exports' do
    context 'when the export file exists' do
      subject(:bulk_action) { described_class.create!(action_type: :export_cocina_json, user:) }

      before do
        File.write(bulk_action.export_filepath(:cocina_json), 'Report content')
      end

      it 'returns the export' do
        expect(bulk_action.existing_exports).to eq(BulkActions::EXPORT_COCINA_JSON.exports)
      end
    end

    context 'when the export file does not exist' do
      subject(:bulk_action) { described_class.create!(action_type: :export_cocina_json, user:) }

      it 'returns no exports' do
        expect(bulk_action.existing_exports).to be_empty
      end
    end

    context 'when there are no exports configured' do
      subject(:bulk_action) { described_class.create!(action_type: :reindex, user:) }

      it 'returns no exports' do
        expect(bulk_action.existing_exports).to be_empty
      end
    end
  end

  describe '.downloadable_filename?' do
    subject(:bulk_action) { described_class.create!(action_type: :export_cocina_json, user:) }

    it 'allows the log file' do
      expect(bulk_action.downloadable_filename?('log.txt')).to be true
    end

    it 'allows a configured export file' do
      expect(bulk_action.downloadable_filename?('cocina.jsonl.gz')).to be true
    end

    it 'does not allow other files' do
      expect(bulk_action.downloadable_filename?('tags.csv')).to be false
      expect(bulk_action.downloadable_filename?('../../secrets.yml')).to be false
    end
  end

  describe '#name' do
    it 'returns the name with the description' do
      expect(described_class.new(id: 5, description: 'Reindex books').name).to eq('Bulk action 5: Reindex books')
    end

    context 'when there is no description' do
      it 'returns the name without the description' do
        expect(described_class.new(id: 5, description: '').name).to eq('Bulk action 5')
      end
    end
  end

  describe '#cancellable?' do
    let(:config) { BulkActions::Config.new }

    before do
      allow(BulkActions).to receive(:find_config).and_return(config)
    end

    it 'returns true when queued or started' do
      expect(described_class.new(status: :queued).cancellable?).to be true
      expect(described_class.new(status: :started).cancellable?).to be true
    end

    it 'returns false when not queued or started' do
      expect(described_class.new(status: :created).cancellable?).to be false
      expect(described_class.new(status: :completed).cancellable?).to be false
      expect(described_class.new(status: :cancelling).cancellable?).to be false
      expect(described_class.new(status: :cancelled).cancellable?).to be false
    end

    context 'when the config is not cancellable' do
      let(:config) { BulkActions::Config.new(cancellable: false) }

      it 'returns false' do
        expect(described_class.new(status: :started).cancellable?).to be false
      end
    end
  end

  describe '#clearable?' do
    it 'returns true when completed or cancelled' do
      expect(described_class.new(status: :completed).clearable?).to be true
      expect(described_class.new(status: :cancelled).clearable?).to be true
    end

    it 'returns false when not finished' do
      expect(described_class.new(status: :created).clearable?).to be false
      expect(described_class.new(status: :queued).clearable?).to be false
      expect(described_class.new(status: :started).clearable?).to be false
      expect(described_class.new(status: :cancelling).clearable?).to be false
    end
  end

  describe 'creating and removing output directory' do
    subject(:bulk_action) { described_class.create!(action_type: :reindex, user:) }

    it 'creates the output directory on create and removes it on destroy' do
      expect(Dir.exist?(bulk_action.output_directory)).to be true

      bulk_action.destroy

      expect(Dir.exist?(bulk_action.output_directory)).to be false
    end
  end
end
