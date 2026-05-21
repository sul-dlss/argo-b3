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
          catalogLinks: [{
            catalog: 'folio', catalogRecordId: 'in11403803', refresh: true, partLabel: 'Part 1',
            sortKey: '001'
          }]
        }
      )
    end
    let(:source_id) { 'test:123' }
    let(:view) { 'world' }

    it 'returns a hash with the source_id from the cocina object' do
      expect(result).to eq(
        source_id:,
        access_view: view,
        folio_catalog_links_attributes: [
          { catalog_record_id: 'in11403803' }
        ],
        catalog_link_refresh: true,
        catalog_link_part_label: 'Part 1',
        catalog_link_sort_key: '001'
      )
    end
  end
end
