# frozen_string_literal: true

module SearchResults
  # Search results that return counts for workflow processes
  class WorkflowProcessCounts
    def initialize(solr_response:)
      @solr_response = solr_response
    end

    # @param process_name [String] the name of the process, e.g., publish
    # @param status [String] the status of the process, e.g., completed
    def count_for(process_name:, status:)
      count_map[[process_name, status]] || 0
    end

    private

    attr_reader :solr_response

    def count_map
      @count_map ||= {}.tap do |hash|
        @solr_response['facets'][Search::Fields::WPS_HIERARCHICAL_WORKFLOWS]['buckets'].each do |bucket|
          # For example, 3|accessionWF:sdr-ingest-received:completed|-
          val_parts = bucket['val'].split('|')
          wf_parts = val_parts[1].split(':')
          hash[[wf_parts[1], wf_parts[2]]] = bucket['count']
        end
      end
    end
  end
end
