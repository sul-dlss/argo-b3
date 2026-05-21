# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModelMappers::DroMapper do
  describe '.call' do
    subject(:result) { described_class.call(cocina_object:) }

    let(:source_id) { 'test:123' }
    let(:license) { 'https://creativecommons.org/publicdomain/zero/1.0/legalcode' }
    let(:use_and_reproduction_statement) { 'This is a use and reproduction statement.' }
    let(:copyright) { 'Copyright © Stanford University. All Rights Reserved.' }
    let(:view) { 'stanford' }
    let(:download) { 'location-based' }
    let(:location) { Constants::ACCESS_LOCATIONS.first }

    let(:embargo_release_date) { DateTime.parse('2040-06-01') }
    let(:embargo_view) { 'location-based' }
    let(:embargo_download) { 'location-based' }
    let(:embargo_location) { Constants::ACCESS_LOCATIONS.first }
    let(:cocina_object) do
      build(:dro_with_metadata, source_id:).new(
        access: {
          view:,
          download:,
          location:,
          useAndReproductionStatement: use_and_reproduction_statement,
          license:,
          copyright:,
          embargo: {
            releaseDate: embargo_release_date,
            view: embargo_view,
            download: embargo_download,
            location: embargo_location
          }
        }
      )
    end

    it 'returns a hash from the cocina object' do
      expect(result).to eq(
        source_id:,
        use_and_reproduction_statement:,
        license:,
        copyright:,
        access_view: view,
        access_download: download,
        access_location: location,
        embargo_release_date:,
        embargo_view:,
        embargo_download:,
        embargo_location:,
        barcode: nil,
        content_type: cocina_object.type,
        viewing_direction: nil,
        symphony_catalog_links_attributes: [],
        previous_symphony_catalog_links_attributes: [],
        folio_catalog_links_attributes: [],
        previous_folio_catalog_links_attributes: []
      )
    end

    context 'when the cocina object has no embargo' do
      let(:cocina_object) do
        build(:dro_with_metadata, source_id:).new(
          access: {
            view:,
            download:,
            location:,
            useAndReproductionStatement: use_and_reproduction_statement,
            license:,
            copyright:
          }
        )
      end

      it 'returns a hash with nil embargo fields' do
        expect(result).to include(
          embargo_release_date: nil,
          embargo_view: nil,
          embargo_download: nil,
          embargo_location: nil
        )
      end
    end

    context 'when the cocina object has a symphony catalog link' do
      let(:cocina_object) do
        build(:dro_with_metadata, source_id:).new(
          identification: {
            sourceId: source_id,
            catalogLinks: [{ catalog: 'symphony', catalogRecordId: '12345', refresh: true }]
          }
        )
      end

      it 'maps symphony_catalog_links_attributes' do
        expect(result).to include(
          symphony_catalog_links_attributes: [{ catalog_record_id: '12345', refresh: true }]
        )
      end
    end

    context 'when the cocina object has a previous symphony catalog link' do
      let(:cocina_object) do
        build(:dro_with_metadata, source_id:).new(
          identification: {
            sourceId: source_id,
            catalogLinks: [{ catalog: 'previous symphony', catalogRecordId: '67890', refresh: false }]
          }
        )
      end

      it 'maps previous_symphony_catalog_links_attributes' do
        expect(result).to include(
          previous_symphony_catalog_links_attributes: [{ catalog_record_id: '67890', refresh: false }]
        )
      end
    end

    context 'when the cocina object has a folio catalog link' do
      let(:cocina_object) do
        build(:dro_with_metadata, source_id:).new(
          identification: {
            sourceId: source_id,
            catalogLinks: [{ catalog: 'folio', catalogRecordId: 'in11403803', refresh: true,
                             partLabel: 'vol. 1', sortKey: 'vol. 00001' }]
          }
        )
      end

      it 'maps folio_catalog_links_attributes including part_label and sort_key' do
        expect(result).to include(
          folio_catalog_links_attributes: [
            { catalog_record_id: 'in11403803', refresh: true, part_label: 'vol. 1', sort_key: 'vol. 00001' }
          ]
        )
      end
    end

    context 'when the cocina object has a previous folio catalog link' do
      let(:cocina_object) do
        build(:dro_with_metadata, source_id:).new(
          identification: {
            sourceId: source_id,
            catalogLinks: [{ catalog: 'previous folio', catalogRecordId: 'a12345678', refresh: false }]
          }
        )
      end

      it 'maps previous_folio_catalog_links_attributes' do
        expect(result).to include(
          previous_folio_catalog_links_attributes: [
            { catalog_record_id: 'a12345678', refresh: false, part_label: nil, sort_key: nil }
          ]
        )
      end
    end

    context 'when the cocina object has a barcode' do
      let(:barcode) { '36105010362304' }
      let(:cocina_object) do
        build(:dro_with_metadata, source_id:).new(
          identification: { sourceId: source_id, barcode: }
        )
      end

      it 'maps the barcode' do
        expect(result).to include(barcode:)
      end
    end

    context 'when hasMemberOrders contains a viewing direction' do
      let(:cocina_object) do
        build(:dro_with_metadata, source_id:).new(
          access: {
            view:,
            download:,
            location:,
            useAndReproductionStatement: use_and_reproduction_statement,
            license:,
            copyright:
          },
          structural: { hasMemberOrders: [{ viewingDirection: 'right-to-left' }] }
        )
      end

      it 'maps viewing_direction from hasMemberOrders' do
        expect(result[:viewing_direction]).to eq('right-to-left')
      end
    end
  end
end
