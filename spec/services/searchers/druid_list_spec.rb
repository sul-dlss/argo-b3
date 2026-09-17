# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::DruidList do
  let(:user) { create(:user, :admin) }
  let(:workgroups) { user.groups }
  let(:druids) { described_class.call(search_form:, workgroups:) }
  let(:search_form) { SearchForm.new(query:) }
  let(:query) { 'test' }
  let(:solr_response) do
    {
      'response' => {
        'numFound' => 1,
        'docs' => [
          { 'id' => 'druid:fm262cb0015' },
          { 'id' => 'druid:rt276nw8963' }
        ]
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns druids from Solr' do
    expect(druids).to eq(['druid:fm262cb0015', 'druid:rt276nw8963'])

    # This tests the parts of the query that aren't tested by ItemQueryBuilder spec.
    expect(Search::SolrService).to have_received(:post) do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['q']).to eq(query)
      expect(solr_query['fl']).to eq([Search::Fields::ID])
      expect(solr_query['rows']).to eq(10_000_000)
    end
  end

  context 'with specific permission targets', :solr do
    let(:user) { create(:user, :reader) }
    let(:restricted_apo_druid) { 'druid:bc123df4567' }
    let!(:visible_document) { create(:solr_item) }
    let(:search_form) { SearchForm.new(query: 'Test') }

    before do
      allow(Search::SolrService).to receive(:post).and_call_original
      create(:solr_item, apo_druid: restricted_apo_druid)
      create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: restricted_apo_druid)
    end

    it 'filters bulk-action and workflow selections to readable items' do
      druids = described_class.call(search_form:, workgroups:)

      expect(druids).to eq([visible_document.fetch(Search::Fields::ID)])
    end
  end
end
