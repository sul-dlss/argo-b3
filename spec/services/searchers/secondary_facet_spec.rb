# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::SecondaryFacet do
  let(:user) { create(:user, :admin) }
  let(:user_scope) { Permissions::UserScope.new(groups: user.groups) }
  let(:results) { described_class.call(search_form:, user_scope:) }
  let(:search_form) { ResultsSearchForm.new(query:) }
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
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns search results from Solr' do
    expect(results).to be_a(SearchResults::Items)
    expect(results.solr_response).to eq(solr_response)

    # This tests the parts of the query that aren't tested by ItemQueryBuilder or FacetsBuilder spec.
    expect(Search::SolrService).to have_received(:post) do |args|
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

  context 'with specific permission targets', :solr do
    let(:user) { create(:user, :reader) }
    let(:restricted_apo_druid) { 'druid:bc123df4567' }
    let(:search_form) { ResultsSearchForm.new(query: 'Test', access_rights_exclude: ['dark']) }

    before do
      allow(Search::SolrService).to receive(:post).and_call_original
      create(:solr_item)
      create(:solr_item, apo_druid: restricted_apo_druid)
      create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: restricted_apo_druid)
    end

    it 'retains authorization when a facet excludes its own selected filter' do
      expect(results.total_results).to eq(0)
      expect(results.solr_response.fetch('facets').fetch(Search::Fields::ACCESS_RIGHTS).fetch('buckets'))
        .to eq([{ 'val' => 'dark', 'count' => 1 }, { 'val' => 'stanford', 'count' => 1 }])
    end
  end
end
