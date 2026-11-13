# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::RedepositJob do
  subject(:job) { described_class.new(bulk_action:, druids: [druid], version_description: 'Reaccession') }

  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:bulk_action) { create(:bulk_action, action_type: 'redeposit', user:) }
  let(:log) { StringIO.new }
  let(:edit_target_druid) { druid }

  let(:cocina_object) { build(:dro_with_metadata, id: druid, version: 2) }
  let(:version_service) { version_service_double(druid:, open?: true, version: 2, version_description:) }
  let(:version_description) { 'Fixed title' }
  let(:workflow_name) { 'assemblyWF' }

  before do
    create(:permission, :edit, workgroup: user.groups.first, target_druid: edit_target_druid)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(Sdr::VersionService).to receive(:new).with(druid:).and_return(version_service)
    allow(version_service).to receive(:open)
    allow(Sdr::DepositDraftService).to receive(:call).and_return(workflow_name)
  end

  after do
    bulk_action.remove_output_directory!
  end

  context 'when the version is closed' do
    let(:version_service) { version_service_double(druid:, open?: false, openable?: true, closed?: true) }

    it 'opens a new version with the version description and deposits it' do
      job.perform_now

      expect(version_service).to have_received(:open).with(description: 'Reaccession',
                                                           opening_user_name: user.sunetid)
      expect(Sdr::DepositDraftService).to have_received(:call)
        .with(cocina_object:, user_name: user.sunetid, lane_id: 'default')

      expect(bulk_action.reload.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
      expect(log.string).to include('Opened new version (Reaccession)')
      expect(log.string).to include('Started assemblyWF, which will close the version')
      expect(log.string).to include("#{druid}\tSuccess: Object successfully redeposited")
    end
  end

  context 'when the version is open with a version description' do
    it 'keeps the version description and deposits the draft' do
      job.perform_now

      expect(version_service).not_to have_received(:open)
      expect(version_service).not_to have_received(:update_description)
      expect(Sdr::DepositDraftService).to have_received(:call)

      expect(bulk_action.reload.druid_count_success).to eq(1)
    end
  end

  context 'when the version is open without a version description' do
    let(:version_description) { nil }

    it 'sets the version description and deposits the draft' do
      job.perform_now

      expect(version_service).to have_received(:update_description).with(description: 'Reaccession',
                                                                         user_name: user.sunetid)
      expect(Sdr::DepositDraftService).to have_received(:call)

      expect(bulk_action.reload.druid_count_success).to eq(1)
      expect(log.string).to include('Updated version description (Reaccession)')
    end
  end

  context 'when the version is closed and cannot be opened' do
    let(:version_service) { version_service_double(druid:, open?: false, openable?: false, closed?: true) }

    it 'does not deposit the object' do
      job.perform_now

      expect(version_service).not_to have_received(:open)
      expect(Sdr::DepositDraftService).not_to have_received(:call)

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(log.string)
        .to include("#{druid}\tError: Version cannot be opened (e.g., the object is being accessioned)")
    end
  end

  context 'when the draft cannot be deposited' do
    before do
      allow(Sdr::DepositDraftService).to receive(:call)
        .and_raise(Sdr::DepositDraftService::UnsavedChangesError, 'Files have unsaved changes')
    end

    it 'records the failure' do
      job.perform_now

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(log.string).to include("#{druid}\tError: Not deposited: Files have unsaved changes")
    end
  end

  context 'when the user lacks update permission' do
    let(:edit_target_druid) { 'druid:cd222df3333' }

    it 'does not redeposit the object' do
      job.perform_now

      expect(version_service).not_to have_received(:open)
      expect(Sdr::DepositDraftService).not_to have_received(:call)

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(log.string).to include("#{druid}\tError: Not authorized to update")
    end
  end
end
