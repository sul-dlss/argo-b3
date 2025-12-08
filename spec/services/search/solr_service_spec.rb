# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::SolrService do
  describe '#post' do
    let(:solr_client) { instance_double(RSolr::Client, post: response) }
    let(:request) { { q: 'test' } }
    let(:response) { { 'response' => { 'numFound' => 10, 'docs' => [] } } }

    before do
      allow(Search::SolrFactory).to receive(:call).and_return(solr_client)
    end

    it 'sends a POST request to Solr with the given data' do
      expect(described_class.post(request:)).to eq(response)

      expect(Search::SolrFactory).to have_received(:call)
      expect(solr_client).to have_received(:post).with('select', data: request, params: {})
    end

    context 'when CSV is requested' do
      let(:request) { { q: 'test', wt: :csv } }

      it 'provides the wt parameter' do
        described_class.post(request:)

        expect(Search::SolrFactory).to have_received(:call)
        expect(solr_client).to have_received(:post).with(
          'select',
          data: request,
          params: { wt: :csv }
        )
      end
    end
  end

  describe '#stream', :solr do
    let(:stream) { StringIO.new }
    let(:replacement_header) { "Druid,PURL\n" }
    let(:druid) { 'druid:bb001nx1648' }

    let(:request) do
      {
        fl: [Search::Fields::BARE_DRUID, Search::Fields::PURL],
        rows: 10,
        wt: :csv,
        fq: "id:(\"#{druid}\")"
      }
    end

    before do
      create(:solr_item, druid:)
    end

    it 'sends a POST request to Solr and streams the response' do
      described_class.stream(request:, stream:, replacement_header:)

      expect(stream.string).to eq("Druid,PURL\nbb001nx1648,https://purl.stanford.edu/bb001nx1648\n")
    end
  end
end
