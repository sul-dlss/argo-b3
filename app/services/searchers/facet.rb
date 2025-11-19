# frozen_string_literal: true

module Searchers
  # Searcher for a basic facet
  class Facet
    include Search::Fields

    def self.call(...)
      new(...).call
    end

    # @param search_form [Search::ItemForm]
    # @param field [String] the Solr field to facet on
    # @param alpha_sort [Boolean] whether to sort facet values alphabetically
    # @param limit [Integer, nil] maximum number of facet values to return
    # @param facet_query [String, nil] optional query to filter facet values
    def initialize(search_form:, field:, alpha_sort: false, limit: nil, facet_query: nil)
      @search_form = search_form
      @field = field
      @alpha_sort = alpha_sort
      @limit = limit
      @facet_query = facet_query
    end

    # @return [SearchResults::FacetCounts] search results
    def call
      SearchResults::FacetCounts.new(solr_response:, field:)
    end

    private

    attr_reader :search_form, :field, :alpha_sort, :limit, :facet_query

    def solr_response
      Search::SolrService.call(request: solr_request)
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
        field => Search::FacetBuilder.call(field:, alpha_sort:, limit:, facet_query:)
      }
    end
  end
end
