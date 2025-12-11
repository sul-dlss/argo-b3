# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::DruidList do
  let(:druids) { described_class.call(search_form:) }
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
end
