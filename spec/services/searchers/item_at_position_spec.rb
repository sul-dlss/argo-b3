# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::ItemAtPosition do
  let(:druid) { described_class.call(search_form:, position:) }
  let(:search_form) { SearchForm.new(query:) }
  let(:query) { 'test' }
  let(:position) { 3 }
  let(:solr_response) do
    {
      'response' => {
        'numFound' => 10,
        'docs' => [
          { 'id' => 'druid:fm262cb0015' }
        ]
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns the druid at the given position' do
    expect(druid).to eq('druid:fm262cb0015')

    expect(Search::SolrService).to have_received(:post) do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['q']).to eq(query)
      expect(solr_query['fl']).to eq([Search::Fields::ID])
      expect(solr_query['rows']).to eq(1)
      expect(solr_query['start']).to eq(2)
    end
  end

  context 'when the position is out of range' do
    let(:solr_response) { { 'response' => { 'numFound' => 10, 'docs' => [] } } }

    it 'returns nil' do
      expect(druid).to be_nil
    end
  end

  context 'when a sort is specified' do
    let(:search_form) { SearchForm.new(query:, sort: 'druid') }

    it 'includes the sort value in the Solr request' do
      druid

      expect(Search::SolrService).to have_received(:post) do |args|
        expect(args[:request].with_indifferent_access['sort']).to eq('id asc')
      end
    end
  end
end
