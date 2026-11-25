# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::RefreshMetadataJob do
  subject(:job) { described_class.new(bulk_action:, druids: [druid], close_version: false) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:bulk_action) { create(:bulk_action) }

  let(:cocina_object) do
    build(:dro_with_metadata, id: druid, folio_instance_hrids: ['a123'])
  end

  let(:refreshed_cocina_object) { cocina_object.new(lock: 'refreshed-lock') }

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, refresh_descriptive_metadata_from_ils: true)
  end

  let(:version_service) { version_service_double(open?: false, openable?: true, closeable?: false, open: nil) }

  let(:job_item) do
    described_class::JobItem.new(druid:, index: 0, job:).tap do |job_item|
      allow(job_item).to receive(:deposit_if_needed!)
      allow(job_item).to receive_messages(check_update_ability?: true, cocina_object:)
    end
  end

  let(:log) { instance_double(File, puts: nil, close: true) }

  before do
    allow(described_class::JobItem).to receive(:new).and_return(job_item)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Sdr::VersionService).to receive(:new).and_return(version_service)
    allow(Sdr::Repository).to receive(:find).and_return(refreshed_cocina_object)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
  end

  it 'opens a version, refreshes the metadata as the user, and deposits if needed' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(version_service).to have_received(:open)
      .with(description: 'Refresh from FOLIO', opening_user_name: bulk_action.user.sunetid)
    expect(object_client).to have_received(:refresh_descriptive_metadata_from_ils)
      .with(user_name: bulk_action.user.sunetid)
    expect(log).to have_received(:puts).with(/Opened new version \(Refresh from FOLIO\)/)
    expect(job_item).to have_received(:deposit_if_needed!)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
    expect(bulk_action.druid_count_success).to eq(1)
  end

  context 'when the version is open' do
    let(:version_service) { version_service_double(open?: true, version_description: 'Fixed the title') }

    it 'keeps the open version and its description' do
      job.perform_now

      expect(object_client).to have_received(:refresh_descriptive_metadata_from_ils)
      expect(version_service).not_to have_received(:update_description)
      expect(log).not_to have_received(:puts).with(/Opened new version/)
      expect(bulk_action.reload.druid_count_success).to eq(1)
    end
  end

  context 'with a mutable content' do
    let(:version_service) { version_service_double(open?: true) }
    let!(:content) { Contents::Builder.call(cocina_object:, immutable: false) }

    it 'moves the content to the refreshed lock' do
      job.perform_now

      expect(content.reload.lock).to eq 'refreshed-lock'
    end
  end

  context 'when the refresh fails' do
    let(:response) { instance_double(Faraday::Response, status: 400, body: nil, reason_phrase: 'Not found in catalog') }

    before do
      allow(object_client).to receive(:refresh_descriptive_metadata_from_ils)
        .and_raise(Dor::Services::Client::UnexpectedResponse.new(response:))
    end

    it 'records a failure and does not deposit' do
      job.perform_now

      expect(job_item).not_to have_received(:deposit_if_needed!)
      expect(log).to have_received(:puts).with(/Refreshing from FOLIO failed: .*Not found in catalog/)
      expect(bulk_action.reload.druid_count_fail).to eq(1)
    end
  end

  context 'when the object is an APO' do
    let(:cocina_object) { build(:admin_policy_with_metadata, id: druid) }

    it 'does not refresh the metadata' do
      job.perform_now

      expect(object_client).not_to have_received(:refresh_descriptive_metadata_from_ils)

      expect(log).to have_received(:puts).with(/Not an item or collection/)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when catalog_record_id is missing' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid) }

    it 'does not refresh the metadata' do
      job.perform_now

      expect(object_client).not_to have_received(:refresh_descriptive_metadata_from_ils)

      expect(log).to have_received(:puts).with(/#{druid}\tError: Does not have a Folio Instance HRID/)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when refresh is set to false' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid).new(
        identification: {
          catalogLinks: [{ catalog: 'folio', catalogRecordId: 'a45678', refresh: false }],
          sourceId: 'sul:1234'
        }
      )
    end

    it 'does not refresh the metadata' do
      job.perform_now

      expect(object_client).not_to have_received(:refresh_descriptive_metadata_from_ils)

      expect(log).to have_received(:puts).with(/#{druid}\tError: Refresh is set to false/)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when the user lacks update ability' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not refresh the metadata' do
      job.perform_now

      expect(object_client).not_to have_received(:refresh_descriptive_metadata_from_ils)
    end
  end
end
