# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaObjectMutators::CollectionMutator do
  subject(:result) { described_class.call(cocina_object:, cocina_model:) }

  let(:cocina_object) { build(:collection_with_metadata) }
  let(:cocina_model) { CocinaModels::Collection.new(cocina_object) }

  context 'when the cocina model has an updated source_id' do
    let(:new_source_id) { 'new:source-id' }

    before { cocina_model.source_id = new_source_id }

    it 'returns a mutated CollectionWithMetadata' do
      expect(result).to be_a(Cocina::Models::CollectionWithMetadata)
      expect(result.identification.sourceId).to eq(new_source_id)
      expect(result.lock).to eq(cocina_object.lock)
    end
  end
end
