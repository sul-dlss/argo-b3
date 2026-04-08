# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::SingleItemByDruid do
  subject(:result) { described_class.call(druid:, fields:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:fields) { Searchers::Item::FIELD_LIST }
  let(:solr_response) do
    {
      'response' => {
        'docs' => [
          { Search::Fields::ID => druid, Search::Fields::TITLE => 'Test title' }
        ]
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns an item from Solr' do
    expect(result).to be_a(SearchResults::Item)
    expect(result.druid).to eq(druid)

    expect(Search::SolrService).to have_received(:post) do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['fq']).to eq(%(id:("#{druid}")))
      expect(solr_query['fl']).to eq(fields)
      expect(solr_query['rows']).to eq(1)
    end
  end

  context 'when custom fields are provided' do
    let(:fields) { [Search::Fields::ID, Search::Fields::COLLECTION_DRUIDS] }

    it 'uses the provided fields' do
      result

      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['fl']).to eq(fields)
      end
    end
  end
end
