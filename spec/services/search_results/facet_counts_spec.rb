# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchResults::FacetCounts do
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
            { 'val' => 'item', 'count' => 5 },
            { 'val' => 'collection', 'count' => 2 },
            { 'val' => 'agreement', 'count' => 3 },
            { 'val' => 'virtual object', 'count' => 3 },
            { 'val' => 'APO', 'count' => 4 }
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
  let(:facet_config) { Search::Facets::Config.new(field:) }
  let(:field) { 'object_types' }
  let(:facet_json) do
    {
      field => {
        type: 'terms',
        field: Search::Fields::OBJECT_TYPES,
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
                                       { value: 'APO', count: 4 }
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

  context 'when the facet config is composite' do
    let(:facet_config) { Search::Facets::ADMIN_POLICIES }
    let(:field) { Search::Fields::APO_TITLE_DRUID }
    let(:solr_response) do
      {
        'responseHeader' => { 'params' => { 'json.facet' => facet_json.to_json } },
        'facets' => {
          field => {
            'buckets' => [{ 'val' => 'University Archives:druid:bc123df4567', 'count' => 5 }],
            'numBuckets' => 1
          }
        }
      }
    end

    it 'parses the druid and label out of each composite bucket value' do
      facet_count = facet_counts.first
      expect(facet_count.value).to eq 'druid:bc123df4567'
      expect(facet_count.label).to eq 'University Archives'
      expect(facet_count.count).to eq 5
    end
  end

  context 'when the facet config offers a missing value' do
    let(:facet_config) { Search::Facets::LANGUAGES }
    let(:field) { Search::Fields::LANGUAGES }
    let(:missing_count) { 7 }
    let(:solr_response) do
      {
        'responseHeader' => { 'params' => { 'json.facet' => facet_json.to_json } },
        'facets' => {
          field => {
            'buckets' => [{ 'val' => 'English', 'count' => 5 }],
            'missing' => { 'count' => missing_count },
            'numBuckets' => 1
          }
        }
      }
    end

    it 'yields No value first' do
      expect(facet_counts.map { |facet_count| [facet_count.value, facet_count.label, facet_count.count] })
        .to eq([['_missing_value', 'No value', 7], ['English', 'English', 5]])
    end

    context 'when not the first page' do
      let(:offset) { 25 }

      it 'does not yield No value' do
        expect(facet_counts.map(&:value)).to eq(['English'])
      end
    end

    context 'when the missing count is 0' do
      let(:missing_count) { 0 }

      it 'does not yield No value' do
        expect(facet_counts.map(&:value)).to eq(['English'])
      end
    end
  end

  context 'when the facet config does not offer a missing value' do
    let(:solr_response) do
      {
        'responseHeader' => { 'params' => { 'json.facet' => facet_json.to_json } },
        'facets' => {
          field => {
            'buckets' => [{ 'val' => 'item', 'count' => 5 }],
            'missing' => { 'count' => 7 },
            'numBuckets' => 1
          }
        }
      }
    end

    it 'does not yield No value' do
      expect(facet_counts.map(&:value)).to eq(['item'])
    end
  end
end
