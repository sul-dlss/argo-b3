# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::SolrFactory do
  it 'returns a Solr client' do
    solr_client = described_class.call

    expect(solr_client).to be_an_instance_of(RSolr::Client)
    expect(solr_client.options[:url]).to eq(Settings.solr.url)
  end
end
