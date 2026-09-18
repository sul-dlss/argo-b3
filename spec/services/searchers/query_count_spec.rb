# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::QueryCount do
  let(:user) { create(:user, :admin) }
  let(:count) { described_class.call(query:) }
  let(:query) { 'member_of_collection_ssim:"druid:bb123cd4567"' }
  let(:solr_response) do
    {
      'response' => {
        'numFound' => 12
      }
    }
  end

  before do
    Current.effective_groups = user.groups
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns the number of matching objects' do
    expect(count).to eq(12)

    expect(Search::SolrService).to have_received(:post) do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['q']).to eq(query)
      expect(solr_query['rows']).to eq(0)
    end
  end

  context 'with an APO query' do
    let(:query) { 'governed_by_ssim:"druid:cc123cd4578"' }

    it 'counts objects matching the query' do
      expect(count).to eq(12)

      expect(Search::SolrService).to have_received(:post) do |args|
        expect(args[:request][:q]).to eq(query)
      end
    end
  end
end
