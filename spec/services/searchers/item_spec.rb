# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::Item do
  let(:results) { described_class.call(search_form:) }
  let(:search_form) { Search::ItemForm.new(query:) }
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

    # This tests the parts of the query that aren't tested by ItemQueryBuilder spec.
    expect(Search::SolrService).to have_received(:call) do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['q']).to eq(query)
      # Only testing one field here so that the test is not brittle.
      expect(solr_query['fl']).to include(Search::Fields::ID)
      expect(solr_query['facet']).to be true
      # Only testing one field here so that the test is not brittle.
      expect(solr_query['facet.field']).to include(
        "{!ex=#{Search::Fields::OBJECT_TYPE}}#{Search::Fields::OBJECT_TYPE}",
        Search::Fields::ACCESS_RIGHTS
      )
      expect(solr_query["f.#{Search::Fields::ACCESS_RIGHTS}.facet.sort"]).to eq('index')
      expect(solr_query["f.#{Search::Fields::ACCESS_RIGHTS}.facet.limit"]).to eq(50)
      expect(solr_query['rows']).to eq(20)
      expect(solr_query['start']).to eq(0)
    end
  end

  context 'when the search form is blank' do
    let(:search_form) { Search::ItemForm.new }

    it 'sets rows to 0' do
      results
      expect(Search::SolrService).to have_received(:call) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['rows']).to eq(0)
      end
    end
  end

  context 'when on page 3' do
    let(:search_form) { Search::ItemForm.new(query:, page: 3) }

    it 'calculates the correct start value' do
      results
      expect(Search::SolrService).to have_received(:call) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['start']).to eq(40)
      end
    end
  end
end
