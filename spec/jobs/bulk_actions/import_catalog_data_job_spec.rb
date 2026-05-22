# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ImportCatalogDataJob do
  subject(:job) { described_class.new(bulk_action:, csv_file:, close_version: false) }

  let(:druid) { 'druid:bc123df4567' }
  let(:folio_instance_hrid) { 'in00000012345' }
  let(:barcode) { '36105010101010' }

  let(:cocina_object) do
    build(:dro_with_metadata, id: druid, folio_instance_hrids: [folio_instance_hrid], barcode:)
  end

  let(:bulk_action) { create(:bulk_action) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }
  let(:log) { StringIO.new }

  let(:csv_file) do
    [
      'druid,folio_instance_hrid,refresh,part_label,sort_key,barcode',
      [druid, new_folio_instance_hrid, new_refresh_value, new_part_label, new_sort_key, new_barcode].join(',')
    ].join("\n")
  end

  let(:new_folio_instance_hrid) { 'in00000099999' }
  let(:new_refresh_value) { 'true' }
  let(:new_part_label) { '' }
  let(:new_sort_key) { '' }
  let(:new_barcode) { '36105020202020' }

  let(:row) { CSV.parse(csv_file, headers: true).first }

  let(:job_item) do
    described_class::JobItem.new(druid:, index: 2, job:, row:).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:check_update_ability?).and_return(true)
      allow(job_item).to receive(:close_version_if_needed!)
    end
  end

  before do
    allow(described_class::JobItem).to receive(:new).and_return(job_item)
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:update)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  it 'updates catalog data for the object' do
    job.perform_now

    expect(described_class::JobItem)
      .to have_received(:new).with(druid:, index: 2, job:, row:)

    expect(job_item).to have_received(:check_update_ability?)
    expect(job_item).to have_received(:open_new_version_if_needed!)
      .with(description: 'Updated FOLIO HRID, barcode, or serials metadata')
    expect(Sdr::Repository).to have_received(:update) do |args|
      identification = args[:cocina_object].identification
      folio_links = identification.catalogLinks.select { |l| l.catalog == 'folio' }
      expect(folio_links.map(&:catalogRecordId)).to eq [new_folio_instance_hrid]
      expect(folio_links.first.refresh).to be true
      expect(identification.barcode).to eq new_barcode
      expect(args[:user_name]).to eq bulk_action.user.sunetid
      expect(args[:description]).to eq 'Updated FOLIO HRID, barcode, or serials metadata'
    end
    expect(job_item).to have_received(:close_version_if_needed!)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when adding multiple FOLIO Instance HRIDs' do
    let(:csv_file) do
      [
        'druid,folio_instance_hrid,folio_instance_hrid,refresh,part_label,sort_key,barcode',
        [druid, 'in00000011111', 'in00000022222', 'true', '', '', ''].join(',')
      ].join("\n")
    end

    it 'includes all HRIDs in the updated object' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:update) do |args|
        folio_links = args[:cocina_object].identification.catalogLinks.select { |l| l.catalog == 'folio' }
        expect(folio_links.map(&:catalogRecordId)).to eq %w[in00000011111 in00000022222]
      end

      expect(bulk_action.reload.druid_count_success).to eq(1)
    end
  end

  context 'when removing FOLIO Instance HRIDs and barcode' do
    let(:new_folio_instance_hrid) { '' }
    let(:new_barcode) { '' }

    it 'removes all folio links and the barcode from the object' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:update) do |args|
        identification = args[:cocina_object].identification
        folio_links = identification.catalogLinks.select { |l| l.catalog == 'folio' }
        expect(folio_links).to be_empty
        expect(identification.barcode).to be_nil
      end

      expect(log.string).to include('Removing FOLIO Instance HRIDs')
      expect(log.string).to include('Removing barcode')
      expect(bulk_action.reload.druid_count_success).to eq(1)
    end
  end

  context 'when the object has serials metadata (part_label and sort_key)' do
    let(:new_part_label) { 'Part 1' }
    let(:new_sort_key) { '1' }

    it 'sets part_label and sort_key on the folio link' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:update) do |args|
        folio_links = args[:cocina_object].identification.catalogLinks.select { |l| l.catalog == 'folio' }
        expect(folio_links.first.partLabel).to eq 'Part 1'
        expect(folio_links.first.sortKey).to eq '1'
      end

      expect(bulk_action.reload.druid_count_success).to eq(1)
    end
  end

  context 'when no changes are present' do
    let(:new_folio_instance_hrid) { folio_instance_hrid }
    let(:new_refresh_value) { 'true' }
    let(:new_barcode) { barcode }

    it 'does not update the object' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include('No changes to catalog data')
      expect(bulk_action.reload.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end

  context 'when the user is not authorized to update' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not update the catalog data' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
    end
  end

  context 'when the object is an admin policy' do
    let(:cocina_object) { build(:admin_policy_with_metadata, id: druid) }

    it 'records a failure' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when the barcode is invalid' do
    let(:new_barcode) { 'not-a-valid-barcode' }

    it 'records a failure and does not update the object' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include('Barcode is not a valid barcode')
      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when the object is a collection' do
    let(:collection_druid) { 'druid:rn873py9109' }
    let(:cocina_object) do
      build(:collection_with_metadata, id: collection_druid, folio_instance_hrids: ['in00000012345'])
    end

    let(:csv_file) do
      [
        'druid,folio_instance_hrid,refresh',
        [collection_druid, 'in00000099999', 'true'].join(',')
      ].join("\n")
    end

    before do
      allow(Dor::Services::Client).to receive(:object).with(collection_druid).and_return(object_client)
    end

    it 'updates FOLIO HRIDs without a barcode' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:update) do |args|
        identification = args[:cocina_object].identification
        folio_links = identification.catalogLinks.select { |link| link.catalog == 'folio' }
        expect(folio_links.map(&:catalogRecordId)).to eq ['in00000099999']
        expect(args[:cocina_object]).to be_a(Cocina::Models::CollectionWithMetadata)
      end

      expect(bulk_action.reload.druid_count_success).to eq(1)
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
    end
  end
end
