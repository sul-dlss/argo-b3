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

  describe '.report_file?' do
    context 'when the report file exists' do
      subject(:bulk_action) { described_class.create!(action_type: :export_cocina_json, user:) }

      before do
        File.write(bulk_action.report_filepath, 'Report content')
      end

      it 'returns true' do
        expect(bulk_action.report_file?).to be true
      end
    end

    context 'when the report file does not exist' do
      subject(:bulk_action) { described_class.create!(action_type: :export_cocina_json, user:) }

      it 'returns false' do
        expect(bulk_action.report_file?).to be false
      end
    end

    context 'when there is no report filename configured' do
      subject(:bulk_action) { described_class.create!(action_type: :reindex, user:) }

      it 'returns false' do
        expect(bulk_action.report_file?).to be false
      end
    end
  end

  describe '.report_filepath' do
    subject(:bulk_action) { described_class.create!(action_type: :export_cocina_json, user:) }

    it 'returns the correct report file path' do
      expect(bulk_action.report_filepath)
        .to eq(File.join(Settings.bulk_actions.directory, "export_cocina_json_#{bulk_action.id}", 'cocina.jsonl.gz'))
    end
  end

  describe '.report_label' do
    subject(:bulk_action) { described_class.create!(action_type: :export_cocina_json, user:) }

    it 'returns the configured report label' do
      expect(bulk_action.report_label).to eq('Cocina JSON')
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
