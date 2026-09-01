# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::UpdateGoverningApoJob do
  subject(:job) { described_class.new(bulk_action:, druids: [druid], close_version: false, new_apo_id:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:new_apo_id) { 'druid:bk123gh4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }

  let(:bulk_action) { create(:bulk_action) }
  let(:log) { StringIO.new }

  let(:job_item) do
    described_class::JobItem.new(druid:, index: 0, job:).tap do |item|
      allow(item).to receive(:can_update_governing_apo?).and_return(true)
      allow(item).to receive(:open_new_version_if_needed!)
      allow(item).to receive(:close_version_if_needed!)
    end
  end

  before do
    allow(described_class::JobItem).to receive(:new).and_return(job_item)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(Sdr::Repository).to receive(:update)
  end

  it 'updates the governing APO' do
    job.perform_now

    expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Updated governing APO')
    expect(Sdr::Repository).to have_received(:update) do |args|
      expect(args[:cocina_object].administrative.hasAdminPolicy).to eq new_apo_id
      expect(args[:user_name]).to eq bulk_action.user.sunetid
      expect(args[:description]).to eq 'Updated governing APO'
    end
    expect(job_item).to have_received(:close_version_if_needed!)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when the object is a collection' do
    let(:cocina_object) { build(:collection_with_metadata, id: druid) }

    it 'updates the governing APO' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:update) do |args|
        expect(args[:cocina_object].administrative.hasAdminPolicy).to eq new_apo_id
      end
    end
  end

  context 'when the object is an admin policy' do
    let(:cocina_object) { build(:admin_policy_with_metadata, id: druid) }

    it 'does not update the object and logs an error' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
      expect(log.string).to include('Not an item or collection')

      expect(bulk_action.reload.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end

  context 'when the user is not authorized to manage the governing APO' do
    before do
      allow(job_item).to receive(:can_update_governing_apo?).and_return(false)
    end

    it 'does not update the object' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
      expect(log.string).to include("Not authorized to move item to #{new_apo_id}")

      expect(bulk_action.reload.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end

  context 'when unchanged' do
    let(:new_apo_id) { cocina_object.administrative.hasAdminPolicy }

    it 'does not update the object' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
      expect(log.string).to include('No changes to governing APO')

      expect(bulk_action.reload.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end

  describe '#can_update_governing_apo?' do
    subject(:job_item) { described_class::JobItem.new(druid:, index: 0, job:) }

    let(:workgroup) { 'sdr:test-workgroup' }
    let(:job_user) { create(:user, groups: [workgroup]) }
    let(:job) { instance_double(described_class, user: job_user, new_apo_id:) }

    before do
      allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    end

    context 'when the user is an admin' do
      let(:job_user) { create(:user, :admin) }

      it 'allows the update without any edit permissions' do
        expect(job_item.send(:can_update_governing_apo?)).to be true
      end
    end

    context 'when the user has edit permission on both the current and new APO' do
      before do
        create(:permission, :edit, workgroup:, target_druid: cocina_object.administrative.hasAdminPolicy)
        create(:permission, :edit, workgroup:, target_druid: new_apo_id)
      end

      it 'allows the update' do
        expect(job_item.send(:can_update_governing_apo?)).to be true
      end
    end

    context 'when the user lacks edit permission on the new APO' do
      before do
        create(:permission, :edit, workgroup:, target_druid: cocina_object.administrative.hasAdminPolicy)
      end

      it 'does not allow the update' do
        expect(job_item.send(:can_update_governing_apo?)).to be false
      end
    end

    context 'when the user lacks edit permission on the current APO' do
      before do
        create(:permission, :edit, workgroup:, target_druid: new_apo_id)
      end

      it 'does not allow the update' do
        expect(job_item.send(:can_update_governing_apo?)).to be false
      end
    end
  end
end
