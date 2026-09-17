# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::Item do
  let(:user) { create(:user, :admin) }
  let(:results) { described_class.call(search_form:) }
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
    Current.effective_groups = user.groups
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns search results from Solr' do
    expect(results).to be_a(SearchResults::Items)
    expect(results.solr_response).to eq(solr_response)

    # This tests the parts of the query that aren't tested by ItemQueryBuilder spec.
    expect(Search::SolrService).to have_received(:post) do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['q']).to eq(query)
      # Only testing one field here so that the test is not brittle.
      expect(solr_query['fl']).to include(Search::Fields::ID)
      # Only testing one field here so that the test is not brittle.
      facet_json = JSON.parse(solr_query[:'json.facet']).with_indifferent_access
      expect(facet_json).to include(
        Search::Fields::OBJECT_TYPES
      )
      expect(solr_query['rows']).to eq(20)
      expect(solr_query['start']).to eq(0)
    end
  end

  context 'when the search form is blank' do
    let(:search_form) { ResultsSearchForm.new }

    it 'sets rows to 0' do
      results
      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['rows']).to eq(0)
      end
    end
  end

  context 'when on page 3' do
    let(:search_form) { ResultsSearchForm.new(query:, page: 3) }

    it 'calculates the correct start value' do
      results
      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['start']).to eq(40)
      end
    end
  end

  context 'with specific permission targets', :solr do
    let(:user) { create(:user, :reader) }
    let(:restricted_apo_druid) { 'druid:bc123df4567' }
    let!(:visible_document) { create(:solr_item) }
    let(:search_form) { ResultsSearchForm.new(query: 'Test') }

    before do
      Current.effective_groups = user.groups
      allow(Search::SolrService).to receive(:post).and_call_original
      create(:solr_item, apo_druid: restricted_apo_druid, content_type: 'image')
      create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: restricted_apo_druid)
    end

    it 'filters results, counts, and facets to only readable items' do
      results = described_class.call(search_form:)

      expect(results.map(&:druid)).to eq([visible_document.fetch(Search::Fields::ID)])
      expect(results.total_results).to eq(1)
      expect(results.solr_response.fetch('facets').fetch(Search::Fields::CONTENT_TYPES).fetch('buckets'))
        .to eq([{ 'val' => 'book', 'count' => 1 }])
    end

    it 'retains authorization when a facet excludes its own selected filter' do
      results = described_class.call(search_form: ResultsSearchForm.new(query: 'Test', content_types: ['image']))

      expect(results.total_results).to eq(0)
      expect(results.solr_response.fetch('facets').fetch(Search::Fields::CONTENT_TYPES).fetch('buckets'))
        .to eq([{ 'val' => 'book', 'count' => 1 }])
    end
  end
end
