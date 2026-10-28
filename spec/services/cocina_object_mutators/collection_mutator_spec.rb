# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaObjectMutators::CollectionMutator do
  subject(:result) { described_class.call(cocina_object:, cocina_model:) }

  let(:cocina_object) { build(:collection_with_metadata) }
  let(:cocina_model) { CocinaModels::Collection.build_from_cocina_object(cocina_object) }

  context 'when the cocina model has an updated source_id' do
    let(:new_source_id) { 'new:source-id' }
    let(:access_view) { 'world' }

    before do
      cocina_model.source_id = new_source_id
      cocina_model.access_view = access_view
    end

    it 'returns a mutated CollectionWithMetadata' do
      expect(result).to be_a(Cocina::Models::CollectionWithMetadata)
      expect(result.identification.sourceId).to eq(new_source_id)
      expect(result.access.view).to eq(access_view)
      expect(result.lock).to eq(cocina_object.lock)
    end
  end

  context 'when the cocina model has updated rights' do
    before do
      cocina_model.use_and_reproduction_statement = 'Use at will.'
      cocina_model.copyright = 'Copyright © Stanford.'
      cocina_model.license = 'https://creativecommons.org/licenses/by/4.0/legalcode'
    end

    it 'returns a CollectionWithMetadata with the rights' do
      expect(result.access.useAndReproductionStatement).to eq('Use at will.')
      expect(result.access.copyright).to eq('Copyright © Stanford.')
      expect(result.access.license).to eq('https://creativecommons.org/licenses/by/4.0/legalcode')
    end
  end

  context 'when the cocina model has blank rights' do
    let(:cocina_object) do
      build(:collection_with_metadata).new(
        access: { view: 'world', useAndReproductionStatement: 'Use at will.', copyright: 'Copyright © Stanford.',
                  license: 'https://creativecommons.org/licenses/by/4.0/legalcode' }
      )
    end

    before do
      cocina_model.use_and_reproduction_statement = ''
      cocina_model.copyright = ''
      cocina_model.license = ''
    end

    it 'returns a CollectionWithMetadata without the rights' do
      expect(result.access.useAndReproductionStatement).to be_nil
      expect(result.access.copyright).to be_nil
      expect(result.access.license).to be_nil
    end
  end
end
