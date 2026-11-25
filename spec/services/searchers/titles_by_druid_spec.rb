# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::TitlesByDruid do
  subject(:titles) { described_class.call(druids:) }

  let(:druids) { %w[druid:xz987wv6543 druid:gh456jk7890 druid:xz987wv6543] }
  let(:solr_response) do
    { 'response' => { 'numFound' => 1, 'start' => 0,
                      'docs' => [{ 'id' => 'druid:xz987wv6543', 'display_title_ss' => 'Maps' }] } }
  end

  before do
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns each title, falling back to the bare druid for objects not in Solr' do
    expect(titles).to eq('druid:xz987wv6543' => 'Maps', 'druid:gh456jk7890' => 'gh456jk7890')

    expect(Search::SolrService).to have_received(:post) do |request:|
      expect(request).to include(fq: ['id:("druid:xz987wv6543" OR "druid:gh456jk7890")'],
                                 fl: %w[id display_title_ss], rows: 2)
    end
  end

  context 'without druids' do
    let(:druids) { [] }

    it 'returns no titles without querying Solr' do
      expect(titles).to eq({})
      expect(Search::SolrService).not_to have_received(:post)
    end
  end
end
