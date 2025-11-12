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
    def initialize(search_form:, field:, alpha_sort: false, limit: nil)
      @search_form = search_form
      @field = field
      @alpha_sort = alpha_sort
      @limit = limit
    end

    # @return [SearchResults::FacetCounts] search results
    def call
      SearchResults::FacetCounts.new(solr_response:, field:)
    end

    private

    attr_reader :search_form, :field, :alpha_sort, :limit

    def solr_response
      Search::SolrService.call(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:).merge(
        {
          facet: true,
          'facet.field': [field],
          rows: 0
        }.tap do |req|
          req['facet.sort'] = 'alpha' if alpha_sort
          req['facet.limit'] = limit if limit
        end
      )
    end
  end
end
