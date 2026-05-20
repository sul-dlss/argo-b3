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
        content_type: cocina_object.type,
        viewing_direction: nil
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
