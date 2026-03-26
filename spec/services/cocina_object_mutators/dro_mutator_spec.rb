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

    before do
      cocina_model.source_id = new_source_id
      cocina_model.license = license
      cocina_model.use_and_reproduction_statement = use_and_reproduction_statement
      cocina_model.copyright = copyright
    end

    it 'mutates the DROWithMetadata' do
      expect(result).to be_a(Cocina::Models::DROWithMetadata)
      expect(result.identification.sourceId).to eq(new_source_id)
      expect(result.access.license).to eq(license)
      expect(result.access.useAndReproductionStatement).to eq(use_and_reproduction_statement)
      expect(result.access.copyright).to eq(copyright)
      expect(result.lock).to eq(cocina_object.lock)
    end
  end
end
