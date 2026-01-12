# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::PurgeJob do
  subject(:job) { described_class.new(bulk_action:, druids: [druid]) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:bulk_action) { create(:bulk_action) }

  let(:job_item) do
    described_class::PurgeJobItem.new(druid:, index: 0, job:).tap do |job_item|
      allow(job_item).to receive(:check_update_ability?).and_return(true)
    end
  end

  let(:purge_service) { instance_double(Sdr::PurgeService, purge: nil) }

  before do
    allow(described_class::PurgeJobItem).to receive(:new).and_return(job_item)
    allow(Sdr::PurgeService).to receive(:new).with(druid:).and_return(purge_service)
  end

  after do
    bulk_action.remove_output_directory!
  end

  context 'when not already submitted' do
    before do
      allow(purge_service).to receive(:can_purge?).and_return(true)
      allow(purge_service).to receive(:purge)
    end

    it 'performs the job' do
      job.perform_now

      expect(job_item).to have_received(:check_update_ability?)
      expect(purge_service).to have_received(:can_purge?)
      expect(purge_service).to have_received(:purge).with(user_name: bulk_action.user.sunetid)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
      expect(bulk_action.druid_count_success).to eq(1)
    end
  end

  context 'when already submitted' do
    before do
      allow(purge_service).to receive(:can_purge?).and_return(false)
    end

    it 'does not purge the object' do
      job.perform_now

      expect(purge_service).not_to have_received(:purge)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when the user lacks update ability' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not purge the object' do
      job.perform_now

      expect(purge_service).not_to have_received(:purge)
    end
  end
end
