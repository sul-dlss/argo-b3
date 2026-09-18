# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::DruidFacetQuery do
  let(:results) do
    described_class.call(search_form:, facet_config: Search::Facets::COLLECTIONS,
                         facet_query: 'Rumsey', limit: 25)
  end
  let(:search_form) { ResultsSearchForm.new(query: 'map') }
  let(:collection_druid) { 'druid:bc123df4567' }
  let(:label_response) do
    {
      'response' => {
        'docs' => [
          {
            Search::Fields::ID => collection_druid,
            Search::Fields::TITLE => 'David Rumsey Map Collection'
          }
        ]
      }
    }
  end
  let(:facet_response) do
    {
      'responseHeader' => {
        'params' => {
          'json.facet' => {
            Search::Fields::COLLECTION_DRUIDS => {
              type: 'terms',
              field: Search::Fields::COLLECTION_DRUIDS,
              sort: 'count',
              numBuckets: true,
              limit: 25
            }
          }.to_json
        }
      },
      'facets' => {
        Search::Fields::COLLECTION_DRUIDS => {
          'buckets' => [{ 'val' => collection_druid, 'count' => 3 }]
        }
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:post).and_return(label_response, facet_response)
  end

  it 'searches labels but returns druid facet values and counts' do
    expect(results.first).to have_attributes(
      value: collection_druid,
      label: 'David Rumsey Map Collection',
      count: 3
    )

    expect(Search::SolrService).to have_received(:post).with(
      request: hash_including(
        q: 'Rumsey',
        fq: "#{Search::Fields::OBJECT_TYPES}:collection",
        fl: [Search::Fields::ID, Search::Fields::TITLE]
      )
    )
    expect(Search::SolrService).to have_received(:post).with(request: hash_including(rows: 0)) do |args|
      request = args.fetch(:request)
      expect(request[:q]).to eq('map')
      expect(request[:fq]).to include(
        %(#{Search::Fields::COLLECTION_DRUIDS}:("druid\\:bc123df4567"))
      )
    end
  end

  context 'when no labels match' do
    let(:label_response) { { 'response' => { 'docs' => [] } } }

    it 'returns no facet values without issuing a count query' do
      expect(results.to_a).to be_empty

      expect(Search::SolrService).to have_received(:post).once
    end
  end
end
