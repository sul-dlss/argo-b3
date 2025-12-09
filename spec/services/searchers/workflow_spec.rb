# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::Workflow do
  subject(:searcher) { described_class.new(search_form:, workflow_name:) }

  let(:search_form) { SearchForm.new(query: 'test') }
  let(:workflow_name) { 'preservationIngestWF' }

  let(:solr_response) do
    {
      'facets' => {
        'wf_hierarchical_wps_ssimdv' => {
          'buckets' => [
            { 'val' => '3|preservationIngestWF:start-ingest:completed|-', 'count' => 4_717_947 },
            { 'val' => '3|preservationIngestWF:update-catalog:completed|-', 'count' => 4_717_940 },
            { 'val' => '3|preservationIngestWF:update-catalog:waiting|-', 'count' => 4 },
            { 'val' => '3|preservationIngestWF:update-catalog:error|-', 'count' => 2 },
            { 'val' => '3|preservationIngestWF:update-catalog:skipped|-', 'count' => 1 }
          ]
        }
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  describe '#call' do
    it 'returns WorkflowProcessCounts initialized with the solr response' do
      result = searcher.call
      expect(result).to be_a(SearchResults::WorkflowProcessCounts)
      expect(result.count_for(process_name: 'start-ingest', status: 'completed')).to eq 4_717_947

      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['q']).to eq('test')
        facet_json = JSON.parse(solr_query[:'json.facet']).with_indifferent_access
        expect(facet_json[Search::Fields::WPS_HIERARCHICAL_WORKFLOWS])
          .to match({
            type: 'terms',
            field: Search::Fields::WPS_HIERARCHICAL_WORKFLOWS,
            prefix: "3|#{workflow_name}",
            limit: -1,
            numBuckets: true,
            sort: 'count'
          }.with_indifferent_access)
        expect(solr_query['rows']).to eq(0)
      end
    end
  end
end
