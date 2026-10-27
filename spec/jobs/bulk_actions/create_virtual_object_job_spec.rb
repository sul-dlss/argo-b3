# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::CreateVirtualObjectJob do
  subject(:job) { described_class.new(bulk_action:, csv_file:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:other_druid) { 'druid:fg456hj7890' }
  let(:csv_file) { "#{druid},druid:cd234fg5678,druid:df345gh6789\n#{other_druid},druid:hj567km8901\n" }

  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:other_cocina_object) { build(:dro_with_metadata, id: other_druid) }
  let(:bulk_action) { create(:bulk_action) }
  let(:log) { StringIO.new }

  let(:virtual_objects_client) { instance_double(Dor::Services::Client::VirtualObjects, create: 'http://dor/jobs/123') }
  let(:async_result) { instance_double(Dor::Services::Client::AsyncResult, wait_until_complete: true) }
  let(:version_open) { false }

  before do
    allow(described_class::JobItem).to receive(:new).and_wrap_original do |original, **args|
      original.call(**args).tap do |job_item|
        allow(job_item).to receive(:check_update_ability?).and_return(true)
      end
    end
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(Sdr::Repository).to receive(:find).with(druid: other_druid).and_return(other_cocina_object)
    allow(Sdr::VersionService).to receive(:open?).and_return(version_open)
    allow(Dor::Services::Client).to receive(:virtual_objects).and_return(virtual_objects_client)
    allow(Dor::Services::Client::AsyncResult).to receive(:new).and_return(async_result)
  end

  it 'creates each virtual object' do
    job.perform_now

    expect(virtual_objects_client).to have_received(:create)
      .with(virtual_objects: [{ virtual_object_id: druid, constituent_ids: %w[druid:cd234fg5678 druid:df345gh6789] }])
    expect(virtual_objects_client).to have_received(:create)
      .with(virtual_objects: [{ virtual_object_id: other_druid, constituent_ids: %w[druid:hj567km8901] }])
    expect(Dor::Services::Client::AsyncResult).to have_received(:new).with(url: 'http://dor/jobs/123').twice
    expect(async_result).to have_received(:wait_until_complete).with(timeout_in_seconds: 900).twice

    expect(log.string).to include("line 1\t#{druid}\tSuccess: Created virtual object")
    expect(log.string).to include("line 2\t#{other_druid}\tSuccess: Created virtual object")
    expect(bulk_action.reload.druid_count_total).to eq(2)
    expect(bulk_action.druid_count_success).to eq(2)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when DSA reports errors' do
    let(:async_result) do
      instance_double(Dor::Services::Client::AsyncResult,
                      wait_until_complete: false,
                      errors: [{ druid => ['Item druid:cd234fg5678 is dark',
                                           'Item druid:df345gh6789 has not been accessioned'] }])
    end

    it 'records the failures' do
      job.perform_now

      expect(log.string).to include("line 1\t#{druid}\tError: Item druid:cd234fg5678 is dark; " \
                                    'Item druid:df345gh6789 has not been accessioned')
      expect(bulk_action.reload.druid_count_fail).to eq(2)
    end
  end

  context 'when waiting for DSA times out' do
    let(:async_result) do
      instance_double(Dor::Services::Client::AsyncResult,
                      wait_until_complete: false, errors: ['Not complete after 900 seconds'])
    end

    it 'records the failures' do
      job.perform_now

      expect(log.string).to include("line 1\t#{druid}\tError: Not complete after 900 seconds " \
                                    '(the virtual object may still be created)')
      expect(bulk_action.reload.druid_count_fail).to eq(2)
    end
  end

  context 'when the virtual object has an open version' do
    let(:version_open) { true }

    it 'does not create the virtual object' do
      job.perform_now

      expect(virtual_objects_client).not_to have_received(:create)
      expect(log.string).to include("line 1\t#{druid}\tError: Version is open; deposit or discard the draft first")
      expect(bulk_action.reload.druid_count_fail).to eq(2)
    end
  end

  context 'when the user is not authorized to update the virtual object' do
    before do
      allow(described_class::JobItem).to receive(:new).and_wrap_original do |original, **args|
        original.call(**args).tap do |job_item|
          allow(job_item).to receive(:check_update_ability?).and_return(false)
        end
      end
    end

    it 'does not create the virtual object' do
      job.perform_now

      expect(virtual_objects_client).not_to have_received(:create)
    end
  end

  context 'when the virtual object is not an item' do
    let(:cocina_object) { build(:collection_with_metadata, id: druid) }

    it 'does not create the virtual object' do
      job.perform_now

      # Only for the other virtual object.
      expect(virtual_objects_client).to have_received(:create).once
      expect(log.string)
        .to include("line 1\t#{druid}\tError: Not an item (https://cocina.sul.stanford.edu/models/collection)")
      expect(bulk_action.reload.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end

  context 'when the virtual object is not found' do
    before do
      allow(Sdr::Repository).to receive(:find).with(druid:).and_raise(Sdr::Repository::NotFoundResponse)
    end

    it 'records the failure' do
      job.perform_now

      expect(log.string).to include("line 1\t#{druid}\tError: Object not found")
      expect(bulk_action.reload.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end

  context 'when creating raises an error' do
    before do
      allow(virtual_objects_client).to receive(:create).and_raise(StandardError, 'Something bad happened')
      allow(Honeybadger).to receive(:notify)
      allow(Rails.logger).to receive(:error)
    end

    it 'records the failure, logs, and notifies Honeybadger' do
      job.perform_now

      expect(log.string).to include("line 1\t#{druid}\tError: StandardError Something bad happened")
      expect(Rails.logger).to have_received(:error).with(/Something bad happened/).twice
      expect(Honeybadger).to have_received(:notify).with(instance_of(StandardError)).twice
      expect(bulk_action.reload.druid_count_fail).to eq(2)
    end
  end
end
