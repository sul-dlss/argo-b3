# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchResults::HierarchicalFacetCounts do
  subject(:facet_counts) { described_class.new(solr_response:, field:) }

  let(:solr_response) do
    {
      'facets' => {
        field => {
          'buckets' => [
            { 'val' => '1|Tag A|+', 'count' => 5 },
            { 'val' => '2|Tag A : Tag A1|-', 'count' => 2 },
            { 'val' => '2|Tag A : Tag A2|-', 'count' => 3 },
            { 'val' => '1|Tag B|+', 'count' => 3 },
            { 'val' => '1|Tag B|-', 'count' => 4 }
          ]
        }
      }
    }
  end
  let(:field) { 'tags' }

  describe '#each' do
    it 'yields HierarchicalFacetCount objects' do
      yielded_values = facet_counts.map do |facet_count|
        {
          value: facet_count.value,
          level: facet_count.level,
          leaf_or_branch_indicator: facet_count.leaf_or_branch_indicator,
          count: facet_count.count
        }
      end

      expect(yielded_values).to eq([
                                     { value: 'Tag A', level: 1, leaf_or_branch_indicator: '+', count: 5 },
                                     { value: 'Tag A : Tag A1', level: 2, leaf_or_branch_indicator: '-', count: 2 },
                                     { value: 'Tag A : Tag A2', level: 2, leaf_or_branch_indicator: '-', count: 3 },
                                     { value: 'Tag B', level: 1, leaf_or_branch_indicator: '+', count: 7 }
                                   ])
    end
  end
end
