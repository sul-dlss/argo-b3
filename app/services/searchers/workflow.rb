# frozen_string_literal: true

module Searchers
  # Searcher for retrieving the process counts for a workflow
  class Workflow
    def self.call(...)
      new(...).call
    end

    # @param search_form [SearchForm]
    # @param workflow_name [String] the name of the workflow
    def initialize(search_form:, workflow_name:)
      @search_form = search_form
      @workflow_name = workflow_name
    end

    # @return [SearchResults::FacetCounts] search results
    def call
      SearchResults::WorkflowProcessCounts.new(solr_response:)
    end

    private

    attr_reader :search_form, :workflow_name

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:).merge(
        {
          'json.facet': facet_json.to_json,
          rows: 0
        }
      )
    end

    def facet_json
      {
        field => Search::FacetBuilder.call(
          field:,
          facet_prefix: "3|#{workflow_name}",
          limit: -1
        )
      }
    end

    def field
      Search::Fields::WPS_HIERARCHICAL_WORKFLOWS
    end
  end
end
