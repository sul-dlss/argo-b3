# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::Tag do
  let(:results) { described_class.call(search_form:, field: Search::Fields::PROJECTS_EXPLODED) }
  let(:search_form) { Search::Form.new(query:) }
  let(:query) { 'project 1' }
  let(:solr_response) do
    {
      'response' => {
        'facet_counts' => {
          'facet_fields' => {
            Search::Fields::PROJECTS_EXPLODED => ['Project 1', 2]
          }
        }
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:call).and_return(solr_response)
  end

  it 'returns search results from Solr' do
    expect(results).to be_a(SearchResults::FacetValues)
    expect(results.solr_response).to eq(solr_response)

    expect(Search::SolrService).to have_received(:call)
      .with(request: { q: '*:*',
                       rows: 0,
                       facet: true,
                       'facet.field': Search::Fields::PROJECTS_EXPLODED,
                       'facet.limit': 10_000,
                       'facet.matches': '(?i)(.*(project|1).*){2}',
                       debugQuery: false })
  end

  context 'when the search form has debug enabled' do
    let(:search_form) { Search::Form.new(query:, debug: true) }

    it 'includes debugQuery in the Solr request' do
      results
      expect(Search::SolrService).to have_received(:call)
        .with(request: hash_including(debugQuery: true))
    end
  end
end
