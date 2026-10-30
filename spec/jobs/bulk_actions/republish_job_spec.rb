# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::RepublishJob do
  subject(:job) { described_class.new(bulk_action:, druids: [druid]) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:user) { create(:user) }
  let(:bulk_action) { create(:bulk_action, action_type: 'republish', user:) }
  let(:log) { StringIO.new }
  let(:edit_target_druid) { druid }

  let(:cocina_object) { build(:dro_with_metadata, id: druid) }

  let(:object_client) { instance_double(Dor::Services::Client::Object, publish: true) }

  before do
    create(:permission, :edit, workgroup: user.groups.first, target_druid: edit_target_druid)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Sdr::WorkflowService).to receive(:published?).and_return(true)
  end

  after do
    bulk_action.remove_output_directory!
  end

  it 'performs the job' do
    job.perform_now

    expect(Sdr::WorkflowService).to have_received(:published?).with(druid:)
    expect(object_client).to have_received(:publish).with(lane_id: 'low')

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
    expect(bulk_action.druid_count_success).to eq(1)
  end

  context 'with multiple druids' do
    subject(:job) { described_class.new(bulk_action:, druids: [druid, other_druid]) }

    let(:other_druid) { 'druid:cd222dd3355' }

    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: other_druid)
      allow(Sdr::Repository).to receive(:find).with(druid: other_druid)
                                              .and_return(build(:dro_with_metadata, id: other_druid))
      allow(Dor::Services::Client).to receive(:object).with(other_druid).and_return(object_client)
      allow(Permission).to receive(:where).and_call_original
    end

    it 'looks up the user permissions once' do
      job.perform_now

      expect(bulk_action.reload.druid_count_success).to eq(2)
      expect(Permission).to have_received(:where).with(workgroup: user.groups).once
    end
  end

  context 'when the user lacks update permission' do
    let(:edit_target_druid) { 'druid:cd222df3333' }

    it 'does not publish the object' do
      job.perform_now

      expect(object_client).not_to have_received(:publish)

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(log.string).to include "#{druid}\tError: Not authorized to update"
    end
  end

  context 'with never published item' do
    before do
      allow(Sdr::WorkflowService).to receive(:published?).and_return(false)
    end

    it 'does not publish the object' do
      job.perform_now

      expect(object_client).not_to have_received(:publish)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(log.string).to include "#{druid}\tError: Never previously published"
    end
  end

  context 'with an APO' do
    let(:cocina_object) { build(:admin_policy_with_metadata, id: druid) }

    it 'does not publish the object' do
      job.perform_now

      expect(object_client).not_to have_received(:publish)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(log.string).to include "#{druid}\tError: Not an item or collection"
    end
  end

  context 'with an agreement' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.agreement) }

    it 'does not publish the object' do
      job.perform_now

      expect(object_client).not_to have_received(:publish)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(log.string).to include "#{druid}\tError: Not an item or collection"
    end
  end
end
