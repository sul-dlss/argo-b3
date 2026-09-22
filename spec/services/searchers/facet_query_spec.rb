# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::FacetQuery do
  let(:user) { create(:user, :admin) }
  let(:user_scope) { Permissions::UserScope.new(groups: user.groups) }
  let(:results) { described_class.call(search_form:, facet_config: Search::Facets::MIMETYPES, facet_query: 'project', user_scope:) }
  let(:search_form) { ResultsSearchForm.new(query:) }
  let(:query) { 'test' }
  let(:solr_response) do
    {
      'response' => {
        'facet_counts' => {
          'facet_fields' => {
            Search::Fields::MIMETYPES => ['Project 1', 2, 'Project 2', 1]
          }
        }
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns search results from Solr' do
    expect(results).to be_a(SearchResults::FacetQueryCounts)
    expect(results.solr_response).to eq(solr_response)

    # This tests the parts of the query that aren't tested by ItemQueryBuilder spec.
    expect(Search::SolrService).to have_received(:post) do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['q']).to eq(query)
      expect(solr_query['facet']).to be true
      # Only testing one field here so that the test is not brittle.
      expect(solr_query['facet.field']).to eq([Search::Fields::MIMETYPES])
      expect(solr_query['facet.contains']).to eq('project')
      expect(solr_query['facet.contains.ignoreCase']).to be(true)
      expect(solr_query['rows']).to eq(0)
      expect(solr_query).not_to have_key('facet.sort')
      expect(solr_query).not_to have_key('facet.limit')
    end
  end

  context 'when alpha_sort is true' do
    let(:results) { described_class.call(search_form:, facet_config: Search::Facets::PROJECTS, facet_query: 'project', user_scope:) }

    it 'includes sort in the Solr request' do
      results
      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['facet.sort']).to eq('alpha')
      end
    end
  end

  context 'when limit is provided' do
    let(:results) { described_class.call(search_form:, facet_config: Search::Facets::MIMETYPES, facet_query: 'project', limit: 5, user_scope:) }

    it 'includes limit in the Solr request' do
      results
      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['facet.limit']).to eq(5)
      end
    end
  end
end
