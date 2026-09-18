# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::FacetLabels do
  let(:druids) { ['druid:bc123df4567', 'druid:df456gh7890'] }
  let(:solr_response) do
    {
      'response' => {
        'docs' => [
          {
            Search::Fields::ID => 'druid:bc123df4567',
            Search::Fields::TITLE => 'Collection One'
          },
          {
            Search::Fields::ID => 'druid:df456gh7890',
            Search::Fields::TITLE => 'Collection Two'
          }
        ]
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns titles keyed by druid' do
    expect(described_class.call(druids:)).to eq(
      'druid:bc123df4567' => 'Collection One',
      'druid:df456gh7890' => 'Collection Two'
    )

    expect(Search::SolrService).to have_received(:post) do |args|
      expect(args.fetch(:request)).to include(
        fq: 'id:("druid\\:bc123df4567" OR "druid\\:df456gh7890")',
        fl: [Search::Fields::ID, Search::Fields::TITLE],
        rows: 2
      )
    end
  end

  context 'with no druids' do
    let(:druids) { [] }

    it 'returns no labels without querying Solr' do
      expect(described_class.call(druids:)).to eq({})

      expect(Search::SolrService).not_to have_received(:post)
    end
  end
end
