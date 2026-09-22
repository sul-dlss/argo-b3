# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::CompositeFacetLabels do
  let(:user) { create(:user, :admin) }
  let(:user_scope) { Permissions::UserScope.new(groups: user.groups) }
  let(:apo_druid) { 'druid:bc123df4567' }
  let(:collection_druid) { 'druid:gh456jk7890' }
  let(:search_form) { ResultsSearchForm.new(admin_policy_druids: [apo_druid], collection_druids: [collection_druid]) }

  before do
    allow(Search::SolrService).to receive(:post) do |request:|
      field = JSON.parse(request[:'json.facet']).keys.first
      bucket_val = case field
                   when Search::Fields::APO_TITLE_DRUID then "University Archives:#{apo_druid}"
                   when Search::Fields::COLLECTION_TITLE_DRUIDS then "David Rumsey Map Collection:#{collection_druid}"
                   end
      { 'facets' => { field => { 'buckets' => [{ 'val' => bucket_val }] } } }
    end
  end

  describe '.call' do
    it 'returns a hash of druid to label for each selected composite facet value' do
      expect(described_class.call(search_form:, user_scope:)).to eq(
        apo_druid => 'University Archives',
        collection_druid => 'David Rumsey Map Collection'
      )
    end
  end

  context 'when no composite facets are selected' do
    let(:search_form) { ResultsSearchForm.new }

    it 'returns an empty hash without querying Solr' do
      expect(described_class.call(search_form:, user_scope:)).to eq({})
      expect(Search::SolrService).not_to have_received(:post)
    end
  end
end
