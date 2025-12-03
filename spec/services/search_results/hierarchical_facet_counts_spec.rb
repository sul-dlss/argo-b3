# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchResults::HierarchicalFacetCounts do
  let(:facet_counts) { described_class.new(solr_response:, facet_config:) }
  let(:empty_facet_counts) { described_class.new(solr_response: empty_solr_response, facet_config:) }

  let(:solr_response) do
    {
      'responseHeader' => {
        'params' => {
          'json.facet' => facet_json.to_json
        }
      },
      'facets' => {
        field => {
          'buckets' => [
            { 'val' => '1|Tag A|+', 'count' => 5 },
            { 'val' => '2|Tag A : Tag A1|-', 'count' => 2 },
            { 'val' => '2|Tag A : Tag A2|-', 'count' => 3 },
            { 'val' => '1|Tag B|+', 'count' => 3 },
            { 'val' => '1|Tag B|-', 'count' => 4 }
          ],
          'numBuckets' => 100
        }
      }
    }
  end
  let(:empty_solr_response) do
    {
      'responseHeader' => {
        'params' => {
          'json.facet' => facet_json.to_json
        }
      },
      'facets' => {}
    }
  end
  let(:facet_config) { Search::Facets::Config.new(hierarchical_field: field) }
  let(:field) { 'tags' }
  let(:facet_json) do
    {
      field => {
        type: 'terms',
        field: Search::Fields::PROJECTS_HIERARCHICAL,
        sort: 'index',
        numBuckets: true,
        limit: 25,
        offset:
      }
    }
  end
  let(:offset) { 0 }

  describe '#each' do
    context 'when there are results' do
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

    context 'when there are no results' do
      it 'yields nothing' do
        expect(empty_facet_counts.to_a).to be_empty
      end
    end
  end

  describe '#total_facets' do
    context 'when there are results' do
      it 'returns the total number of facets' do
        expect(facet_counts.total_facets).to eq(100)
      end
    end

    context 'when there are no results' do
      it 'returns 0' do
        expect(empty_facet_counts.total_facets).to eq(0)
      end
    end
  end

  describe '#page' do
    context 'when offset is 0' do
      it 'returns page 1' do
        expect(facet_counts.page).to eq(1)
      end
    end

    context 'when offset is 30' do
      let(:offset) { 30 }

      it 'returns page 2' do
        expect(facet_counts.page).to eq(2)
      end
    end
  end

  describe '#total_pages' do
    context 'when there are results' do
      it 'returns the total number of pages' do
        expect(facet_counts.total_pages).to eq(4)
      end
    end

    context 'when there are no results' do
      it 'returns 0' do
        expect(empty_facet_counts.total_pages).to eq(0)
      end
    end
  end

  describe '#to_ary' do
    it 'returns an array of facet counts' do
      expect(facet_counts.to_ary).to be_an(Array)
      expect(facet_counts.to_ary.size).to eq(4)
    end
  end
end
