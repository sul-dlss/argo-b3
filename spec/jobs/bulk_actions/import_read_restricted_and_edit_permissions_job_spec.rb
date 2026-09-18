# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ImportReadRestrictedAndEditPermissionsJob do
  subject(:job) { described_class.new(bulk_action:, csv_file:) }

  let(:bulk_action) { create(:bulk_action) }
  let(:druid) { 'druid:bc123df4567' }
  let(:workgroup) { 'sdr:baker-staff' }
  let(:cocina_object) { build(:collection_with_metadata, id: druid) }
  let(:log) { StringIO.new }
  let(:host) { 'argo-test.stanford.edu' }

  before do
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(Sdr::Event).to receive(:create)
    allow(Sdr::Event).to receive(:host).and_return(host)
  end

  context 'when granting a read restricted permission for a collection' do
    let(:csv_file) { "permission_type,druid,workgroup\nread_restricted,#{druid},#{workgroup}\n" }

    it 'creates the permission and an event' do
      job.perform_now

      expect(Permission.permission_type_read_restricted.find_by(workgroup:, target_druid: druid)).to be_present
      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
      expect(log.string).to include("Success: Created read restricted permission for #{workgroup}")
      expect(Sdr::Event).to have_received(:create)
        .with(druid:, type: 'argo_permission_created',
              data: { who: bulk_action.user.sunetid, host:, permission_type: 'read_restricted' })
    end
  end

  context 'when granting an edit permission for an APO' do
    let(:cocina_object) { build(:admin_policy_with_metadata, id: druid) }
    let(:csv_file) { "permission_type,druid,workgroup\nedit,#{druid},#{workgroup}\n" }

    it 'creates the permission' do
      job.perform_now

      expect(Permission.permission_type_edit.find_by(workgroup:, target_druid: druid)).to be_present
      expect(bulk_action.reload.druid_count_success).to eq(1)
      expect(log.string).to include("Success: Created edit permission for #{workgroup}")
    end
  end

  context 'when the permission already exists' do
    let(:csv_file) { "permission_type,druid,workgroup\nread_restricted,#{druid},#{workgroup}\n" }

    before do
      create(:permission, :read_restricted, workgroup:, target_druid: druid)
    end

    it 'does not create a duplicate permission and reports a failure' do
      job.perform_now

      expect(Permission.permission_type_read_restricted.where(workgroup:, target_druid: druid).count).to eq(1)
      expect(bulk_action.reload.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(log.string).to include("Error: Read restricted permission already exists for #{workgroup}")
    end
  end

  context 'when the druid is not a collection or APO' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid) }
    let(:csv_file) { "permission_type,druid,workgroup\nread_restricted,#{druid},#{workgroup}\n" }

    it 'reports a failure without creating the permission' do
      job.perform_now

      expect(Permission.permission_type_read_restricted.find_by(workgroup:, target_druid: druid)).to be_nil
      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(log.string).to include('Error: Not a collection or administrative policy')
    end
  end

  context 'when the object is not found' do
    let(:csv_file) { "permission_type,druid,workgroup\nread_restricted,#{druid},#{workgroup}\n" }

    before do
      allow(Sdr::Repository).to receive(:find).with(druid:).and_raise(Sdr::Repository::NotFoundResponse)
    end

    it 'reports a failure without creating the permission' do
      job.perform_now

      expect(Permission.permission_type_read_restricted.find_by(workgroup:, target_druid: druid)).to be_nil
      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(log.string).to include('Error: Object not found')
    end
  end

  context 'when the permission type is blank' do
    let(:other_druid) { 'druid:dd456gh7890' }
    let(:other_workgroup) { 'sdr:hoover-staff' }
    let(:csv_file) { "permission_type,druid,workgroup\n,#{druid},#{workgroup}\n" }

    before do
      create(:permission, :read_restricted, workgroup:, target_druid: druid)
      create(:permission, :edit, workgroup:, target_druid: druid)
      create(:permission, :read_restricted, workgroup: other_workgroup, target_druid: druid)
      create(:permission, :read_restricted, workgroup:, target_druid: other_druid)
    end

    it 'deletes the read restricted and edit permissions for the druid and workgroup only' do
      job.perform_now

      expect(Permission.where(workgroup:, target_druid: druid)).to be_empty
      expect(Permission.where(workgroup: other_workgroup, target_druid: druid).count).to eq(1)
      expect(Permission.where(workgroup:, target_druid: other_druid).count).to eq(1)
      expect(bulk_action.reload.druid_count_success).to eq(1)
      expect(log.string).to include("Success: Deleted 2 permissions for #{workgroup}")
      expect(Sdr::Event).to have_received(:create)
        .with(druid:, type: 'argo_permission_deleted',
              data: { who: bulk_action.user.sunetid, host:, permission_type: 'read_restricted' })
      expect(Sdr::Event).to have_received(:create)
        .with(druid:, type: 'argo_permission_deleted',
              data: { who: bulk_action.user.sunetid, host:, permission_type: 'edit' })
    end
  end

  context 'when the permission type is blank and an admin permission exists for the druid and workgroup' do
    let(:csv_file) { "permission_type,druid,workgroup\n,#{druid},#{workgroup}\n" }

    before do
      create(:permission, :read_restricted, workgroup:, target_druid: druid)
      create(:permission, :admin, workgroup:, target_druid: druid)
    end

    it 'does not delete the admin permission' do
      job.perform_now

      expect(Permission.permission_type_admin.find_by(workgroup:, target_druid: druid)).to be_present
      expect(Permission.permission_type_read_restricted.find_by(workgroup:, target_druid: druid)).to be_nil
      expect(log.string).to include("Success: Deleted 1 permission for #{workgroup}")
    end
  end

  context 'when the permission type is blank and the object is not found' do
    let(:csv_file) { "permission_type,druid,workgroup\n,#{druid},#{workgroup}\n" }

    before do
      create(:permission, :read_restricted, workgroup:, target_druid: druid)
      allow(Sdr::Repository).to receive(:find).with(druid:).and_raise(Sdr::Repository::NotFoundResponse)
    end

    it 'deletes the permission without checking the object type' do
      job.perform_now

      expect(Permission.where(workgroup:, target_druid: druid)).to be_empty
      expect(bulk_action.reload.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end

  context 'when the permission type is blank and there are no permissions to delete' do
    let(:csv_file) { "permission_type,druid,workgroup\n,#{druid},#{workgroup}\n" }

    it 'reports a failure' do
      job.perform_now

      expect(bulk_action.reload.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(log.string).to include("Error: No read restricted or edit permissions to delete for #{workgroup}")
    end
  end

  context 'when the permission type is invalid' do
    let(:csv_file) { "permission_type,druid,workgroup\nadmin,#{druid},#{workgroup}\n" }

    it 'reports a failure without creating the permission' do
      job.perform_now

      expect(Permission.where(workgroup:, target_druid: druid)).to be_empty
      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(log.string).to include('Error: "admin" is not a valid value for "permission_type"')
    end
  end

  context 'when the workgroup is missing' do
    let(:csv_file) { "permission_type,druid,workgroup\nread_restricted,#{druid},\n" }

    it 'reports a failure' do
      job.perform_now

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(log.string).to include('Error: Missing required value for "workgroup"')
    end
  end

  context 'when the druid is missing' do
    let(:csv_file) { "permission_type,druid,workgroup\nread_restricted,,#{workgroup}\n" }

    it 'reports a failure' do
      job.perform_now

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(log.string).to include('Error: Missing required value for "druid"')
    end
  end
end
