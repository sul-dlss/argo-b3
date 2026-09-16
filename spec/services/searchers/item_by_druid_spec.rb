# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::ItemByDruid do
  let(:user) { create(:user, :admin) }
  let(:results) { described_class.call(druids:) }
  let(:druids) { ['druid:rt276nw8963', 'druid:kk754nn3333'] }
  let(:solr_response) do
    {
      'response' => {
        'numFound' => 2,
        'start' => 0,
        'docs' => [
          { 'id' => 'druid:rt276nw8963' },
          { 'id' => 'druid:kk754nn3333' }
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

    expect(Search::SolrService).to have_received(:post) do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['fq']).to eq(['id:("druid:rt276nw8963" OR "druid:kk754nn3333")'])
      expect(solr_query['fl']).to eq(Searchers::Item::FIELD_LIST)
      expect(solr_query['rows']).to eq(2)
    end
  end

  context 'with specific permission targets', :solr do
    let(:user) { create(:user, :reader) }
    let(:restricted_apo_druid) { 'druid:bc123df4567' }
    let!(:visible_document) { create(:solr_item) }
    let!(:hidden_document) { create(:solr_item, apo_druid: restricted_apo_druid) }

    before do
      Current.effective_groups = user.groups
      allow(Search::SolrService).to receive(:post).and_call_original
      create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: restricted_apo_druid)
    end

    it 'only returns readable items from the supplied druids' do
      druids = [visible_document, hidden_document].pluck(Search::Fields::ID)
      results = described_class.call(druids:)

      expect(results.map(&:druid)).to eq([visible_document.fetch(Search::Fields::ID)])
    end
  end
end
