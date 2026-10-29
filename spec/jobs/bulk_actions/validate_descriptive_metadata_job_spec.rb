# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ValidateDescriptiveMetadataJob do
  subject(:job) { described_class.new(bulk_action:, csv_file:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:purl) { "#{Settings.purl.url}/#{druid.delete_prefix('druid:')}" }
  let(:cocina_object) do
    object = build(:dro_with_metadata, id: druid)
    object.new(description: object.description.new(purl:))
  end

  let(:expected_cocina_object) do
    cocina_object.new(description: cocina_object.description.new(title: [{ value: 'new title 1' }], purl:))
  end

  let(:user) { create(:user) }
  let(:bulk_action) { create(:bulk_action, user:) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }
  let(:log) { StringIO.new }
  let(:edit_target_druid) { druid }

  let(:csv_file) do
    [
      'druid,source_id,title1:value',
      [druid, cocina_object.identification.sourceId, 'new title 1'].join(',')
    ].join("\n")
  end

  before do
    create(:permission, :edit, workgroup: user.groups.first, target_druid: edit_target_druid)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:update)
    allow(Dor::Services::Client.objects).to receive(:indexable)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  it 'validates without updating the descriptive metadata' do
    job.perform_now

    expect(Dor::Services::Client.objects).to have_received(:indexable).with(druid:, cocina: expected_cocina_object)
    expect(Sdr::Repository).not_to have_received(:update)

    expect(log.string).to include 'Successfully validated'

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when the user can read but lacks update permission' do
    let(:user) { create(:user, :reader) }
    let(:edit_target_druid) { 'druid:cd222df3333' }

    it 'does not validate the descriptive metadata' do
      job.perform_now

      expect(Dor::Services::Client.objects).not_to have_received(:indexable)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include "#{druid}\tError: Not authorized to update"

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when validation fails' do
    let(:csv_file) do
      [
        'druid,source_id,title1.structuredValue1.value,title1.structuredValue1.type',
        [druid, cocina_object.identification.sourceId, 'new title 1', 'new title 1'].join(',')
      ].join("\n")
    end

    it 'reports the failure' do
      job.perform_now

      expect(Dor::Services::Client.objects).not_to have_received(:indexable)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include 'Unrecognized types in description: title1.structuredValue1 (new title 1)'

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_fail).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
    end
  end

  context 'when index validation fails' do
    let(:response) { instance_double(Faraday::Response, status: 422, body: nil, reason_phrase: 'Example field error') }

    before do
      allow(Dor::Services::Client.objects).to receive(:indexable).and_raise(Dor::Services::Client::UnprocessableContentError.new(response:))
    end

    it 'reports the failure' do
      job.perform_now

      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include "indexing validation failed for #{druid}: Example field error"

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_fail).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
    end
  end
end
