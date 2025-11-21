# frozen_string_literal: true

module Searchers
  # Searcher for performing a facet query.
  # This is a separate searcher because the JSON Facet API does not support "contains".
  # This uses the standard Solr faceting parameters.
  class FacetQuery
    include Search::Fields

    def self.call(...)
      new(...).call
    end

    # @param search_form [Search::ItemForm]
    # @param field [String] the Solr field to facet on
    # @param facet_query [String] query to filter facet values
    # @param alpha_sort [Boolean] whether to sort facet values alphabetically
    # @param limit [Integer, nil] maximum number of facet values to return
    def initialize(search_form:, field:, facet_query:, alpha_sort: false, limit: nil)
      @search_form = search_form
      @field = field
      @alpha_sort = alpha_sort
      @limit = limit
      @facet_query = facet_query
    end

    # @return [SearchResults::FacetQueryCounts] search results
    def call
      SearchResults::FacetQueryCounts.new(solr_response:, field:)
    end

    private

    attr_reader :search_form, :field, :alpha_sort, :limit, :facet_query

    def solr_response
      Search::SolrService.call(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:).merge(
        {
          facet: true,
          'facet.field': [field],
          rows: 0,
          'facet.contains': facet_query,
          'facet.contains.ignoreCase': true
        }.tap do |req|
          req['facet.sort'] = 'alpha' if alpha_sort
          req['facet.limit'] = limit if limit
        end
      )
    end
  end
end
