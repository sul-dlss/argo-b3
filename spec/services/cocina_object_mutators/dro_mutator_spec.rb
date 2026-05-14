# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaObjectMutators::DroMutator do
  subject(:result) { described_class.call(cocina_object:, cocina_model:) }

  let(:cocina_object) { build(:dro_with_metadata) }
  let(:cocina_model) { CocinaModels::Dro.new(cocina_object) }

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
end
