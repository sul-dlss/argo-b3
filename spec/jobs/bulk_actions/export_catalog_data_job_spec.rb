# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ExportCatalogDataJob do
  subject(:job) { described_class.new(bulk_action:, druids: [druid]) }

  let(:druid) { 'druid:bc123df4567' }
  let(:bulk_action) { create(:bulk_action, action_type: 'export_catalog_data') }
  let(:log) { StringIO.new }

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }
  let(:cocina_object) do
    build(:dro_with_metadata,
          id: druid).new(identification: { catalogLinks: [folio_link], barcode: '36105010101010', sourceId: 'sul:123' })
  end
  let(:folio_link) do
    Cocina::Models::FolioCatalogLink.new(
      catalog: 'folio',
      catalogRecordId: 'in00000012345',
      refresh: true,
      partLabel: 'Part 1',
      sortKey: '1'
    )
  end

  before do
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  after do
    bulk_action.remove_output_directory!
  end

  it 'performs the job and writes CSV' do
    job.perform_now

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)

    expect(log.string).to include "Exported catalog data for #{druid}"

    expect(File).to exist(bulk_action.export_filepath)
    csv = CSV.read(bulk_action.export_filepath, headers: true)
    expect(csv.headers).to eq %w[druid folio_instance_hrid refresh part_label sort_key barcode]
    expect(csv[0].to_h.values).to eq [druid, 'in00000012345', 'true', 'Part 1', '1', '36105010101010']
  end

  context 'when the object has no FOLIO catalog link' do
    let(:cocina_object) do
      build(:dro_with_metadata,
            id: druid).new(identification: { catalogLinks: [], barcode: '36105010101010', sourceId: 'sul:123' })
    end

    it 'writes a row with nil FOLIO fields but includes the barcode' do
      job.perform_now

      expect(bulk_action.reload.druid_count_success).to eq(1)
      csv = CSV.read(bulk_action.export_filepath, headers: true)
      expect(csv[0].to_h.values).to eq [druid, nil, nil, nil, nil, '36105010101010']
    end
  end

  context 'when the object has no barcode' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid).new(identification: { catalogLinks: [folio_link], sourceId: 'sul:123' })
    end

    it 'writes a row with nil barcode' do
      job.perform_now

      expect(bulk_action.reload.druid_count_success).to eq(1)
      csv = CSV.read(bulk_action.export_filepath, headers: true)
      expect(csv[0]['barcode']).to be_nil
    end
  end

  context 'when the object is a collection' do
    let(:cocina_object) do
      build(:collection_with_metadata, id: druid)
        .new(identification: { catalogLinks: [folio_link], sourceId: 'sul:123' })
    end

    it 'exports catalog data without a barcode' do
      job.perform_now

      expect(bulk_action.reload.druid_count_success).to eq(1)
      csv = CSV.read(bulk_action.export_filepath, headers: true)
      expect(csv[0].to_h.values).to eq [druid, 'in00000012345', 'true', 'Part 1', '1', nil]
    end
  end

  context 'when the object is an admin policy' do
    let(:cocina_object) { build(:admin_policy_with_metadata, id: druid) }

    it 'records a failure and does not write to CSV' do
      job.perform_now

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(log.string).to include 'Not an item or collection'
    end
  end

  context 'when DSA raises an error' do
    before do
      allow(object_client).to receive(:find).and_raise(Dor::Services::Client::NotFoundResponse, 'object not found')
    end

    it 'records a failure' do
      job.perform_now

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(log.string).to include "Failed Sdr::Repository::NotFoundResponse Object not found: #{druid} for #{druid}"
    end
  end
end
