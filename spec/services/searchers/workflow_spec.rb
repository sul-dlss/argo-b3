# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::Workflow do
  subject(:searcher) { described_class.new(search_form:) }

  let(:user) { create(:user, :reader) }

  let(:search_form) { WorkflowGridSearchForm.new(query: 'test') }

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
    Current.effective_groups = user.groups
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  describe '#call' do
    it 'returns WorkflowProcessCounts initialized with the solr response' do
      result = searcher.call
      expect(result).to be_a(SearchResults::WorkflowProcessCounts)
      expect(result.count_for(workflow_name: 'preservationIngestWF', process_name: 'start-ingest', status: 'completed'))
        .to eq 4_717_947

      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['q']).to eq('test')
        facet_json = JSON.parse(solr_query[:'json.facet']).with_indifferent_access
        expect(facet_json[Search::Fields::WPS_HIERARCHICAL_WORKFLOWS])
          .to match({
            type: 'terms',
            field: Search::Fields::WPS_HIERARCHICAL_WORKFLOWS,
            limit: -1,
            numBuckets: true,
            sort: 'count'
          }.with_indifferent_access)
        expect(solr_query['rows']).to eq(0)
      end
    end
  end

  context 'with specific permission targets', :solr do
    let(:user) { create(:user, :reader) }
    let(:restricted_apo_druid) { 'druid:bc123df4567' }
    let(:workflow) { 'accessionWF:publish:completed' }

    before do
      Current.effective_groups = user.groups
      allow(Search::SolrService).to receive(:post).and_call_original
      create(:solr_item, workflows: [workflow])
      create(:solr_item, apo_druid: restricted_apo_druid, workflows: [workflow])
      create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: restricted_apo_druid)
    end

    it 'only counts workflows on readable items' do
      counts = described_class.call(search_form: WorkflowGridSearchForm.new(query: 'Test'))

      expect(counts.count_for(workflow_name: 'accessionWF', process_name: 'publish', status: 'completed')).to eq(1)
    end
  end
end
