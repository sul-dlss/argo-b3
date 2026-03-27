# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModelMappers::CollectionMapper do
  describe '.call' do
    subject(:result) { described_class.call(cocina_object:) }

    let(:cocina_object) { build(:collection_with_metadata, source_id:) }
    let(:source_id) { 'test:123' }

    it 'returns a hash with the source_id from the cocina object' do
      expect(result).to eq(source_id:)
    end
  end
end
