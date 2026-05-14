# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModelMappers::CollectionMapper do
  describe '.call' do
    subject(:result) { described_class.call(cocina_object:) }

    let(:cocina_object) do
      build(:collection_with_metadata, source_id:).new(
        access: { view: }
      )
    end
    let(:source_id) { 'test:123' }
    let(:view) { 'world' }

    it 'returns a hash with the source_id from the cocina object' do
      expect(result).to eq(
        source_id:,
        access_view: view
      )
    end
  end
end
