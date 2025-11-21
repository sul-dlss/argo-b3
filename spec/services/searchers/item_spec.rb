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
      # Only testing one field here so that the test is not brittle.
      facet_json = JSON.parse(solr_query[:'json.facet']).with_indifferent_access
      expect(facet_json).to include(
        Search::Fields::OBJECT_TYPE,
        Search::Fields::ACCESS_RIGHTS
      )
      expect(facet_json[Search::Fields::ACCESS_RIGHTS])
        .to match({
                    field: Search::Fields::ACCESS_RIGHTS,
                    limit: 50,
                    numBuckets: true,
                    sort: 'index',
                    type: 'terms'
                  })
      # Only testing one dynamic facet here so that the test is not brittle.
      expect(facet_json).to include(
        "#{Search::Facets::RELEASED_TO_EARTHWORKS.form_field}-last_week",
        "#{Search::Facets::RELEASED_TO_EARTHWORKS.form_field}-last_month",
        "#{Search::Facets::RELEASED_TO_EARTHWORKS.form_field}-last_year",
        "#{Search::Facets::RELEASED_TO_EARTHWORKS.form_field}-ever",
        "#{Search::Facets::RELEASED_TO_EARTHWORKS.form_field}-never"
      )
      expect(facet_json["#{Search::Facets::RELEASED_TO_EARTHWORKS.form_field}-last_week"])
        .to match({
                    type: 'query',
                    q: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:[NOW-7DAY/DAY TO NOW]"
                  })
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
