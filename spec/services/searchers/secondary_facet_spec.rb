# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::SecondaryFacet do
  let(:results) { described_class.call(search_form:) }
  let(:search_form) { SearchForm.new(query:) }
  let(:query) { 'test' }
  let(:solr_response) do
    {
      'response' => {
        'numFound' => 1,
        'docs' => [
          { 'id' => 'druid:ab123cd4567' }
        ]
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:call).and_return(solr_response)
  end

  it 'returns search results from Solr' do
    expect(results).to be_a(SearchResults::Items)
    expect(results.solr_response).to eq(solr_response)

    # This tests the parts of the query that aren't tested by ItemQueryBuilder or FacetsBuilder spec.
    expect(Search::SolrService).to have_received(:call) do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['q']).to eq(query)
      # Only testing one field here so that the test is not brittle.
      facet_json = JSON.parse(solr_query[:'json.facet']).with_indifferent_access
      expect(facet_json).to include(
        Search::Fields::ACCESS_RIGHTS
      )
      expect(solr_query['rows']).to eq(0)
    end
  end
end
