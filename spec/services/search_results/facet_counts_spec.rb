# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchResults::FacetCounts do
  let(:facet_counts) { described_class.new(solr_response:, field:) }
  let(:empty_facet_counts) { described_class.new(solr_response: empty_solr_response, field:) }

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
            { 'val' => 'item', 'count' => 5 },
            { 'val' => 'collection', 'count' => 2 },
            { 'val' => 'agreement', 'count' => 3 },
            { 'val' => 'virtual object', 'count' => 3 },
            { 'val' => 'adminPolicy', 'count' => 4 }
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
  let(:field) { 'object_types' }
  let(:facet_json) do
    {
      field => {
        type: 'terms',
        field: Search::Fields::OBJECT_TYPE,
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
      it 'yields FacetCount objects' do
        yielded_values = facet_counts.map do |facet_count|
          {
            value: facet_count.value,
            count: facet_count.count
          }
        end

        expect(yielded_values).to eq([
                                       { value: 'item', count: 5 },
                                       { value: 'collection', count: 2 },
                                       { value: 'agreement', count: 3 },
                                       { value: 'virtual object', count: 3 },
                                       { value: 'adminPolicy', count: 4 }
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
      expect(facet_counts.to_ary.size).to eq(5)
    end
  end
end
