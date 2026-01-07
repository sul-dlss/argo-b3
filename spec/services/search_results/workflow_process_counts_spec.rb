# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchResults::WorkflowProcessCounts do
  subject(:counts) { described_class.new(solr_response:) }

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

  let(:workflow_name) { 'preservationIngestWF' }

  describe '#count_for' do
    it 'returns the correct counts for process name and status' do
      expect(counts.count_for(workflow_name:, process_name: 'start-ingest', status: 'completed'))
        .to eq 4_717_947
      expect(counts.count_for(workflow_name:, process_name: 'update-catalog', status: 'completed'))
        .to eq 4_717_940
      expect(counts.count_for(workflow_name:, process_name: 'update-catalog', status: 'waiting'))
        .to eq 4
      expect(counts.count_for(workflow_name:, process_name: 'update-catalog', status: 'error'))
        .to eq 2
      expect(counts.count_for(workflow_name:, process_name: 'update-catalog', status: 'skipped'))
        .to eq 1
    end

    it 'returns 0 for unknown workflow, process, and status combinations' do
      expect(counts.count_for(workflow_name: 'nonexistent-workflow', process_name: 'start-ingest', status: 'completed'))
        .to eq 0
      expect(counts.count_for(workflow_name:, process_name: 'nonexistent-process', status: 'completed'))
        .to eq 0
      expect(counts.count_for(workflow_name:, process_name: 'start-ingest', status: 'nonexistent-status'))
        .to eq 0
    end

    context 'with an empty solr response when no results' do
      let(:solr_response) { { 'facets' => { 'count' => 0 } } }

      it 'returns 0 for any workflow, process, and status combination' do
        expect(counts.count_for(workflow_name:, process_name: 'start-ingest', status: 'completed'))
          .to eq 0
        expect(counts.count_for(workflow_name:, process_name: 'update-catalog', status: 'waiting'))
          .to eq 0
      end
    end
  end
end
