# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaObjectMutators::DroMutator do
  subject(:result) { described_class.call(cocina_object:, cocina_model:) }

  let(:cocina_object) { build(:dro_with_metadata) }
  let(:cocina_model) { CocinaModels::Dro.new(cocina_object) }

  context 'when the cocina model has an updated content_type' do
    let(:new_content_type) { Cocina::Models::ObjectType.book }

    before { cocina_model.content_type = new_content_type }

    it 'mutates the type on the DROWithMetadata' do
      expect(result.type).to eq(new_content_type)
      expect(result.lock).to eq(cocina_object.lock)
    end
  end

  context 'when the cocina model has a viewing_direction set' do
    let(:cocina_object) { build(:dro_with_metadata, type: Cocina::Models::ObjectType.book) }

    before do
      cocina_model.viewing_direction = 'right-to-left'
    end

    it 'sets hasMemberOrders with the viewing direction' do
      expect(result.structural.hasMemberOrders.first.viewingDirection).to eq('right-to-left')
    end
  end

  context 'when the cocina model has a blank viewing_direction' do
    it 'sets hasMemberOrders to empty' do
      expect(result.structural.hasMemberOrders).to be_empty
    end
  end

  context 'when the cocina model has an updated source_id' do
    let(:new_source_id) { 'new:source-id' }
    let(:license) { 'https://creativecommons.org/publicdomain/zero/1.0/legalcode' }
    let(:use_and_reproduction_statement) { 'This is a use and reproduction statement.' }
    let(:copyright) { 'Copyright © Stanford University. All Rights Reserved.' }
    let(:access_view) { 'stanford' }
    let(:access_download) { 'location-based' }
    let(:access_location) { 'music' }

    before do
      cocina_model.source_id = new_source_id
      cocina_model.license = license
      cocina_model.use_and_reproduction_statement = use_and_reproduction_statement
      cocina_model.copyright = copyright
      cocina_model.access_view = access_view
      cocina_model.access_download = access_download
      cocina_model.access_location = access_location
    end

    it 'mutates the DROWithMetadata' do
      expect(result).to be_a(Cocina::Models::DROWithMetadata)
      expect(result.identification.sourceId).to eq(new_source_id)
      expect(result.access.license).to eq(license)
      expect(result.access.useAndReproductionStatement).to eq(use_and_reproduction_statement)
      expect(result.access.copyright).to eq(copyright)
      expect(result.access.view).to eq(access_view)
      expect(result.access.download).to eq(access_download)
      expect(result.access.location).to eq(access_location)
      expect(result.lock).to eq(cocina_object.lock)
    end
  end

  context 'when embargo attributes are set' do
    let(:embargo_release_date) { DateTime.parse('2040-06-01') }
    let(:embargo_view) { 'world' }
    let(:embargo_download) { 'none' }

    before do
      cocina_model.embargo_release_date = embargo_release_date
      cocina_model.embargo_view = embargo_view
      cocina_model.embargo_download = embargo_download
    end

    it 'writes the embargo to the DROWithMetadata' do
      expect(result).to be_a(Cocina::Models::DROWithMetadata)
      expect(result.access.embargo.releaseDate).to eq embargo_release_date
      expect(result.access.embargo.view).to eq embargo_view
      expect(result.access.embargo.download).to eq embargo_download
      expect(result.access.embargo.location).to be_nil
      expect(result.lock).to eq(cocina_object.lock)
    end
  end

  context 'when embargo_release_date is nil' do
    it 'does not write an embargo to the DROWithMetadata' do
      expect(result.access.embargo).to be_nil
    end
  end

  context 'when the cocina model has a folio catalog link' do
    before do
      cocina_model.folio_catalog_links_attributes = [{ catalog_record_id: 'in11403803', refresh: true }]
    end

    it 'includes the folio catalog link in the result' do
      folio_link = result.identification.catalogLinks.find { |link| link.catalog == 'folio' }
      expect(folio_link.catalogRecordId).to eq('in11403803')
      expect(folio_link.refresh).to be true
    end
  end

  context 'when the cocina model has a folio catalog link with part_label and sort_key' do
    before do
      cocina_model.folio_catalog_links_attributes = [
        { catalog_record_id: 'in11403803', refresh: false, part_label: 'vol. 1', sort_key: 'vol. 00001' }
      ]
    end

    it 'includes partLabel and sortKey in the result' do
      folio_link = result.identification.catalogLinks.find { |link| link.catalog == 'folio' }
      expect(folio_link.partLabel).to eq('vol. 1')
      expect(folio_link.sortKey).to eq('vol. 00001')
    end
  end

  context 'when the cocina model has a symphony catalog link' do
    before do
      cocina_model.symphony_catalog_links_attributes = [{ catalog_record_id: '11403803', refresh: true }]
    end

    it 'includes the symphony catalog link in the result' do
      symphony_link = result.identification.catalogLinks.find { |link| link.catalog == 'symphony' }
      expect(symphony_link.catalogRecordId).to eq('11403803')
      expect(symphony_link.refresh).to be true
    end
  end

  context 'when the cocina object has existing catalog links' do
    let(:cocina_object) { build(:dro_with_metadata, folio_instance_hrids: ['in11403803']) }

    it 'preserves the existing catalog links in the result' do
      folio_link = result.identification.catalogLinks.find { |link| link.catalog == 'folio' }
      expect(folio_link.catalogRecordId).to eq('in11403803')
    end
  end

  context 'when the cocina model has a barcode' do
    before { cocina_model.barcode = '36105010362304' }

    it 'writes the barcode to the DROWithMetadata identification' do
      expect(result.identification.barcode).to eq('36105010362304')
    end
  end

  context 'when the cocina object has an existing embargo and embargo_release_date is cleared' do
    let(:cocina_object) do
      build(:dro_with_metadata).new(
        access: { view: 'world', download: 'none',
                  embargo: { releaseDate: DateTime.parse('2040-06-01'), view: 'world', download: 'world' } }
      )
    end

    before { cocina_model.embargo_release_date = nil }

    it 'removes the embargo from the DROWithMetadata' do
      expect(result.access.embargo).to be_nil
    end
  end
end
