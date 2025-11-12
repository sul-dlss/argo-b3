# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::SolrService do
  let(:solr_client) { instance_double(RSolr::Client, post: response) }
  let(:request) { { q: 'test' } }
  let(:response) { { 'response' => { 'numFound' => 10, 'docs' => [] } } }

  before do
    allow(Search::SolrFactory).to receive(:call).and_return(solr_client)
  end

  it 'sends a POST request to Solr with the given data' do
    expect(described_class.call(request:)).to eq(response)

    expect(Search::SolrFactory).to have_received(:call)
    expect(solr_client).to have_received(:post).with('select', data: request)
  end
end
