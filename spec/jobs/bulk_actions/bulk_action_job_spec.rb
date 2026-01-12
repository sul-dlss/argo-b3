# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::BulkActionJob do
  # Setting count fields to ensure that they are reset.
  let(:bulk_action) { create(:bulk_action, druid_count_success: 100, druid_count_fail: 100, druid_count_total: 100) }
  let(:druids) { %w[druid:bb111cc2222 druid:cc111dd2222] }
  let(:log) { instance_double(File, puts: nil, close: true) }
  let(:export_file) { instance_double(File, close: true) }

  before do
    bulk_action_job_class = Class.new(described_class)
    stub_const('TestBulkActionJob', bulk_action_job_class)

    allow_any_instance_of(TestBulkActionJob).to receive(:export_file).and_return(export_file) # rubocop:disable RSpec/AnyInstance
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
  end

  after do
    bulk_action.remove_output_directory!
  end

  context 'when no errors' do
    before do
      bulk_action_item_class = Class.new(BulkActions::BulkActionJobItem) do
        def perform
          success!(message: 'Testing successful') if druid == 'druid:bb111cc2222'
          failure!(message: 'Testing failed') if druid == 'druid:cc111dd2222'
        end
      end
      stub_const('TestBulkActionJob::TestBulkActionJobItem', bulk_action_item_class)

      allow(TestBulkActionJob::TestBulkActionJobItem).to receive(:new).and_call_original
    end

    it 'performs the job' do
      TestBulkActionJob.perform_now(bulk_action:, druids:)

      expect(TestBulkActionJob::TestBulkActionJobItem).to have_received(:new).with(druid: druids.first, index: 0,
                                                                                   job: instance_of(TestBulkActionJob))
      expect(TestBulkActionJob::TestBulkActionJobItem).to have_received(:new).with(druid: druids.second, index: 1,
                                                                                   job: instance_of(TestBulkActionJob))

      expect(log).to have_received(:puts).with(/Starting TestBulkActionJob for BulkAction #{bulk_action.id}/)
      expect(log).to have_received(:puts).with(/Finished TestBulkActionJob for BulkAction #{bulk_action.id}/)
      expect(log).to have_received(:puts).with(/Testing successful for #{druids.first}/o)
      expect(log).to have_received(:puts).with(/Testing failed for #{druids.second}/o)
      expect(log).to have_received(:close)
      expect(export_file).to have_received(:close)

      expect(bulk_action.reload.druid_count_total).to eq(2)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.completed?).to be true

      expect(Dir.exist?(bulk_action.output_directory)).to be true

      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to).with('notifications', bulk_action.user,
                                                                                target: 'toast-container',
                                                                                html: kind_of(String))
    end
  end

  context 'when errors' do
    before do
      bulk_action_item_class = Class.new(BulkActions::BulkActionJobItem) do
        def perform
          success!(message: 'Testing successful') if druid == 'druid:bb111cc2222'
          raise StandardError, 'Something bad happened' if druid == 'druid:cc111dd2222'
        end
      end
      stub_const('TestBulkActionJob::TestBulkActionJobItem', bulk_action_item_class)

      allow(TestBulkActionJob::TestBulkActionJobItem).to receive(:new).and_call_original
    end

    it 'performs the job' do
      TestBulkActionJob.perform_now(bulk_action:, druids:)

      expect(log).to have_received(:puts).with(/Testing successful for #{druids.first}/o)
      expect(log).to have_received(:puts).with(/Failed StandardError Something bad happened for #{druids.second}/o)

      expect(bulk_action.reload.druid_count_total).to eq(2)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end
end
