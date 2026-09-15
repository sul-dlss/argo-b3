# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ImportReadUnrestrictedWorkgroupsJob do
  subject(:job) { described_class.new(bulk_action:, csv_file:) }

  let(:bulk_action) { create(:bulk_action) }
  let(:workgroup) { 'sdr:baker-staff' }
  let(:other_workgroup) { 'sdr:hoover-staff' }
  let(:log) { StringIO.new }

  before do
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
  end

  context 'when granting the permission to a workgroup that does not have it' do
    let(:csv_file) { "workgroup,read_unrestricted\n#{workgroup},true\n" }

    it 'creates the permission' do
      job.perform_now

      expect(Permission.permission_type_read_unrestricted.find_by(workgroup:)).to be_present
      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
      expect(log.string).to include("Success: Created read unrestricted permission for #{workgroup}")
    end
  end

  context 'when granting the permission to a workgroup that already has it' do
    let(:csv_file) { "workgroup,read_unrestricted\n#{workgroup},true\n" }

    before do
      create(:permission, :read_unrestricted, workgroup:)
    end

    it 'does not create a duplicate permission and reports a failure' do
      job.perform_now

      expect(Permission.permission_type_read_unrestricted.where(workgroup:).count).to eq(1)
      expect(bulk_action.reload.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(log.string).to include("Error: Read unrestricted permission already exists for #{workgroup}")
    end
  end

  context 'when revoking the permission from a workgroup that has it' do
    let(:csv_file) { "workgroup,read_unrestricted\n#{workgroup},false\n" }

    before do
      create(:permission, :read_unrestricted, workgroup:)
      create(:permission, :read_unrestricted, workgroup: other_workgroup)
    end

    it 'deletes the permission and leaves other workgroups alone' do
      job.perform_now

      expect(Permission.permission_type_read_unrestricted.find_by(workgroup:)).to be_nil
      expect(Permission.permission_type_read_unrestricted.find_by(workgroup: other_workgroup)).to be_present
      expect(bulk_action.reload.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
      expect(log.string).to include("Success: Deleted read unrestricted permission for #{workgroup}")
    end
  end

  context 'when revoking the permission from a workgroup that does not have it' do
    let(:csv_file) { "workgroup,read_unrestricted\n#{workgroup},false\n" }

    it 'reports a failure' do
      job.perform_now

      expect(bulk_action.reload.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(log.string).to include("Error: No read unrestricted permission to delete for #{workgroup}")
    end
  end

  context 'when the read_unrestricted value is invalid' do
    let(:csv_file) { "workgroup,read_unrestricted\n#{workgroup},yes\n" }

    it 'reports a failure without changing permissions' do
      job.perform_now

      expect(Permission.permission_type_read_unrestricted.find_by(workgroup:)).to be_nil
      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(log.string).to include('Error: "yes" is not a valid value for "read_unrestricted"')
    end
  end

  context 'when the workgroup is missing' do
    let(:csv_file) { "workgroup,read_unrestricted\n,true\n" }

    it 'reports a failure' do
      job.perform_now

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(log.string).to include('Error: Missing required value for "workgroup"')
    end
  end

  context 'with multiple rows' do
    let(:csv_file) do
      "workgroup,read_unrestricted\n#{workgroup},true\n#{other_workgroup},false\n"
    end

    before do
      create(:permission, :read_unrestricted, workgroup: other_workgroup)
    end

    it 'processes every row' do
      job.perform_now

      expect(Permission.permission_type_read_unrestricted.find_by(workgroup:)).to be_present
      expect(Permission.permission_type_read_unrestricted.find_by(workgroup: other_workgroup)).to be_nil
      expect(bulk_action.reload.druid_count_total).to eq(2)
      expect(bulk_action.druid_count_success).to eq(2)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end
end
