# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::Tag do
  let(:user) { create(:user, :admin) }
  let(:results) { described_class.call(search_form:, field: Search::Fields::PROJECTS_EXPLODED) }
  let(:search_form) { SearchForm.new(query:) }
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
    Current.effective_groups = user.groups
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns search results from Solr' do
    expect(results).to be_a(SearchResults::FacetValues)
    expect(results.solr_response).to eq(solr_response)

    expect(Search::SolrService).to have_received(:post)
      .with(request: { q: '*:*',
                       fq: [],
                       rows: 0,
                       facet: true,
                       'facet.field': Search::Fields::PROJECTS_EXPLODED,
                       'facet.limit': 10_000,
                       'facet.matches': '(?i)(.*(project|1).*){2}',
                       debugQuery: false })
  end

  context 'when the search form has debug enabled' do
    let(:search_form) { SearchForm.new(query:, debug: true) }

    it 'includes debugQuery in the Solr request' do
      results
      expect(Search::SolrService).to have_received(:post)
        .with(request: hash_including(debugQuery: true))
    end
  end

  context 'with specific permission targets', :solr do
    let(:user) { create(:user, :reader) }
    let(:restricted_apo_druid) { 'druid:bc123df4567' }

    before do
      Current.effective_groups = user.groups
      allow(Search::SolrService).to receive(:post).and_call_original
      create(:solr_item, projects: ['Visible project'])
      create(:solr_item, apo_druid: restricted_apo_druid, projects: ['Hidden project'])
      create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: restricted_apo_druid)
    end

    it 'only returns project tags for readable items' do
      tags = described_class.call(search_form: SearchForm.new(query: 'project'),
                                  field: Search::Fields::PROJECTS_EXPLODED)

      expect(tags.to_a).to eq(['Visible project'])
    end
  end
end
