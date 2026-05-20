# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModelMappers::CollectionMapper do
  describe '.call' do
    subject(:result) { described_class.call(cocina_object:) }

    let(:cocina_object) do
      build(:collection_with_metadata, source_id:).new(
        access: { view: },
        identification: {
          sourceId: source_id,
          catalogLinks: [{ catalog: 'symphony', catalogRecordId: '12345', refresh: true }]
        }
      )
    end
    let(:source_id) { 'test:123' }
    let(:view) { 'world' }

    it 'returns a hash with the source_id from the cocina object' do
      expect(result).to eq(
        source_id:,
        access_view: view,
        symphony_catalog_links_attributes: [
          { catalog_record_id: '12345', refresh: true }
        ],
        previous_symphony_catalog_links_attributes: [],
        folio_catalog_links_attributes: [],
        previous_folio_catalog_links_attributes: []
      )
    end
  end
end
