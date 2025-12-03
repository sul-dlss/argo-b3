# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchResults::Items do
  let(:items) { described_class.new(solr_response:, per_page: 2) }
  let(:offset) { 0 }

  let(:solr_response) do
    {
      'responseHeader' => {
        'params' => {
          'start' => '0',
          'rows' => '2',
          'wt' => 'json'
        }
      },
      'response' => {
        'numFound' => 101,
        'start' => offset,
        'numFoundExact' => true,
        'docs' => [
          {
            Search::Fields::PROJECTS => ['Rigler-Deutsch Index'],
            Search::Fields::ID => 'druid:rt276nw8963',
            Search::Fields::APO_DRUID => ['druid:bz845pv2292'],
            Search::Fields::OBJECT_TYPES => ['item'],
            Search::Fields::TITLE => 'Mark Twain : portrait for orchestra',
            Search::Fields::CONTENT_TYPES => ['image'],
            Search::Fields::APO_TITLE => ['ARS'],
            Search::Fields::BARE_DRUID => 'rt276nw8963'
          },
          {
            Search::Fields::PROJECTS => ['Martin Wong : batch 3'],
            Search::Fields::ID => 'druid:kk754nn3333',
            Search::Fields::APO_DRUID => ['druid:yj997zx7371'],
            Search::Fields::OBJECT_TYPES => ['item'],
            Search::Fields::TITLE => 'Mark Twain',
            Search::Fields::CONTENT_TYPES => ['image'],
            Search::Fields::APO_TITLE => ['Martin Wong Collection'],
            Search::Fields::BARE_DRUID => 'kk754nn3333'
          },
          {
            Search::Fields::PROJECTS => ['ARS LPs'],
            Search::Fields::ID => 'druid:zk509gj4865',
            Search::Fields::APO_DRUID => ['druid:bz845pv2292'],
            Search::Fields::OBJECT_TYPES => ['item'],
            Search::Fields::TITLE => 'Mark Twain tonight',
            Search::Fields::CONTENT_TYPES => ['media'],
            Search::Fields::APO_TITLE => ['ARS'],
            Search::Fields::BARE_DRUID => 'zk509gj4865'
          }
        ]
      },
      'facets' => {
        Search::Fields::ACCESS_RIGHTS => {
          'numBuckets' => 2,
          'buckets' => [
            {
              'val' => 'citation',
              'count' => 6
            },
            {
              'val' => 'dark',
              'count' => 3
            }
          ]
        },
        'released_to_earthworks-ever' => {
          'count' => 0
        },
        'released_to_earthworks-never' => {
          'count' => 101
        }
      }
    }
  end

  describe '#each' do
    it 'yields Item objects' do
      yielded_items = items.map do |item|
        expect(item).to be_a(SearchResults::Item)
        item.druid
      end
      expect(yielded_items).to eq([
                                    'druid:rt276nw8963',
                                    'druid:kk754nn3333',
                                    'druid:zk509gj4865'
                                  ])
    end
  end

  describe '#total_results' do
    it 'returns the total results' do
      expect(items.total_results).to eq(101)
    end
  end

  describe '#page' do
    context 'when offset is 0' do
      it 'returns page 1' do
        expect(items.page).to eq(1)
      end
    end

    context 'when offset is 30' do
      let(:offset) { 3 }

      it 'returns page 2' do
        expect(items.page).to eq(2)
      end
    end
  end

  describe '#total_pages' do
    it 'returns the total number of pages' do
      expect(items.total_pages).to eq(51)
    end
  end

  describe '#to_ary' do
    it 'returns an array of facet counts' do
      expect(items.to_ary).to be_an(Array)
      expect(items.to_ary.size).to eq(3)
    end
  end

  describe 'facet methods (method missing)' do
    it 'returns facet counts for non-dynamic facets' do
      facet_counts = items.access_rights_facet
      expect(facet_counts).to be_a(SearchResults::FacetCounts)
      expect(facet_counts.total_facets).to eq(2)
    end

    it 'returns facet counts for dynamic facets' do
      facet_counts = items.released_to_earthworks_facet
      expect(facet_counts).to be_a(SearchResults::DynamicFacetCounts)
    end
  end
end
