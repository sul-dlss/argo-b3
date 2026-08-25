# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ManageReleaseJob do
  subject(:job) do
    described_class.new(bulk_action:, druids: [druid], to: 'SEARCHWORKS', release: true)
  end

  let(:druid) { 'druid:bb111cc2222' }
  let(:user) { create(:user, email_address: 'bergeraj@stanford.edu') }
  let(:bulk_action) { create(:bulk_action, action_type: 'manage_release', user:) }
  let(:cocina_object) { instance_double(Cocina::Models::DRO, version:) }
  let(:version) { 2 }

  let(:log) { StringIO.new }

  let(:job_item) do
    described_class::JobItem.new(druid:, index: 0, job:).tap do |job_item|
      allow(job_item).to receive_messages(check_update_ability?: true, cocina_object:)
    end
  end

  before do
    allow(described_class::JobItem).to receive(:new).and_return(job_item)
    allow(Sdr::WorkflowService).to receive(:published?).and_return(true)
    allow(Sdr::Repository).to receive(:create_release_tag)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
  end

  it 'performs the job' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(Sdr::WorkflowService).to have_received(:published?).with(druid:)
    expect(Sdr::Repository).to have_received(:create_release_tag)
      .with(druid:, user_name: job_item.user_id, release_target: 'SEARCHWORKS', release: true, release_what: 'self',
            lane_id: 'low')

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
    expect(bulk_action.druid_count_success).to eq(1)
  end

  context 'when the user lacks update ability' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not release the object' do
      job.perform_now

      expect(Sdr::WorkflowService).not_to have_received(:published?)
      expect(Sdr::Repository).not_to have_received(:create_release_tag)
    end
  end

  context 'when the object has never been published' do
    before do
      allow(Sdr::WorkflowService).to receive(:published?).and_return(false)
    end

    it 'does not release the object' do
      job.perform_now

      expect(Sdr::Repository).not_to have_received(:create_release_tag)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end
end
