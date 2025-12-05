# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::Facet do
  let(:results) { described_class.call(search_form:, facet_config:) }
  let(:search_form) { SearchForm.new(query:) }
  let(:query) { 'test' }
  let(:facet_config) { Search::Facets::Config.new(field: Search::Fields::PROJECTS_EXPLODED) }
  let(:solr_response) do
    {
      'facets' => {
        Search::Fields::PROJECTS_EXPLODED => {
          'buckets' => [
            { 'val' => 'Project 1', 'count' => 2 },
            { 'val' => 'Project 2', 'count' => 1 }
          ]
        }
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns search results from Solr' do
    expect(results).to be_a(SearchResults::FacetCounts)
    expect(results.solr_response).to eq(solr_response)

    # This tests the parts of the query that aren't tested by ItemQueryBuilder spec.
    expect(Search::SolrService).to have_received(:post) do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['q']).to eq(query)
      facet_json = JSON.parse(solr_query['json.facet']).with_indifferent_access
      # Only testing one field here so that the test is not brittle.
      expect(facet_json[Search::Fields::PROJECTS_EXPLODED])
        .to match({
                    type: 'terms',
                    field: 'exploded_project_tag_ssimdv',
                    sort: 'count',
                    numBuckets: true
                  })
      expect(solr_query['rows']).to eq(0)
    end
  end

  context 'when alpha_sort is true' do
    let(:facet_config) { Search::Facets::Config.new(field: Search::Fields::PROJECTS_EXPLODED, alpha_sort: true) }

    it 'includes sort in the Solr request' do
      results
      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request]
        facet_json = JSON.parse(solr_query[:'json.facet']).with_indifferent_access
        expect(facet_json[Search::Fields::PROJECTS_EXPLODED][:sort]).to eq('index')
      end
    end
  end

  context 'when limit is provided' do
    let(:results) { described_class.call(search_form:, facet_config:, limit: 5) }

    it 'includes limit in the Solr request' do
      results
      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        facet_json = JSON.parse(solr_query[:'json.facet']).with_indifferent_access
        expect(facet_json[Search::Fields::PROJECTS_EXPLODED][:limit]).to eq(5)
      end
    end
  end
end
