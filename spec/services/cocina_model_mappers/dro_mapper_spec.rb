# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModelMappers::DroMapper do
  describe '.call' do
    subject(:result) { described_class.call(cocina_object:) }

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
    let(:source_id) { 'test:123' }
    let(:license) { 'https://creativecommons.org/publicdomain/zero/1.0/legalcode' }
    let(:use_and_reproduction_statement) { 'This is a use and reproduction statement.' }
    let(:copyright) { 'Copyright © Stanford University. All Rights Reserved.' }
    let(:view) { 'stanford' }
    let(:download) { 'location-based' }
    let(:location) { Constants::ACCESS_LOCATIONS.first }

    it 'returns a hash from the cocina object' do
      expect(result).to eq(
        source_id:,
        use_and_reproduction_statement:,
        license:,
        copyright:,
        access_view: view,
        access_download: download,
        access_location: location
      )
    end
  end
end
