# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::AdminPolicyList do
  let(:apo_options) { described_class.call }
  let(:solr_response) do
    {
      'response' => {
        'numFound' => 2,
        'docs' => [
          { 'id' => 'druid:bc123df4567', 'display_title_ss' => 'APO One' },
          { 'id' => 'druid:xz987wv6543', 'display_title_ss' => 'APO Two' }
        ]
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns [title, druid] pairs from Solr' do
    expect(apo_options).to eq([['APO One', 'druid:bc123df4567'], ['APO Two', 'druid:xz987wv6543']])

    expect(Search::SolrService).to have_received(:post) do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['fq']).to eq("#{Search::Fields::OBJECT_TYPES}:APO")
      expect(solr_query['fl']).to eq([Search::Fields::ID, Search::Fields::TITLE])
    end
  end
end
