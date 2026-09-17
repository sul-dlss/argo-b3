# frozen_string_literal: true

module Searchers
  # Searcher for retrieving the process counts for a workflow
  class Workflow
    def self.call(...)
      new(...).call
    end

    # @param search_form [SearchForm]
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    def initialize(search_form:, user_scope:)
      @search_form = search_form
      @user_scope = user_scope
    end

    # @return [SearchResults::FacetCounts] search results
    def call
      SearchResults::WorkflowProcessCounts.new(solr_response:)
    end

    private

    attr_reader :search_form, :user_scope

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:, user_scope:).merge(
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
          limit: -1
        )
      }
    end

    def field
      Search::Fields::WPS_HIERARCHICAL_WORKFLOWS
    end
  end
end
