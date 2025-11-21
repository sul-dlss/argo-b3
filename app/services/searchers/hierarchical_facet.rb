# frozen_string_literal: true

module Searchers
  # Searcher for a hierarchical facet
  class HierarchicalFacet
    def self.call(...)
      new(...).call
    end

    # @param search_form [Search::ItemForm]
    # @param field [String] the Solr field to facet on
    # @param value [String, nil] the facet value to return children for. If nil, returns top-level values
    # @param alpha_sort [Boolean] whether to sort facet values alphabetically
    # @param limit [Integer, nil] maximum number of facet values to return
    # @param page [Integer, nil] optional page number for paged facets
    def initialize(search_form:, field:, value: nil, alpha_sort: false, limit: nil, page: nil) # rubocop:disable Metrics/ParameterLists
      @search_form = search_form
      @field = field
      @value = value
      @alpha_sort = alpha_sort
      @limit = limit
      @page = page
    end

    # @return [SearchResults::FacetCounts] search results
    def call
      SearchResults::HierarchicalFacetCounts.new(solr_response:, field:)
    end

    private

    attr_reader :search_form, :field, :alpha_sort, :limit, :value, :page

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
        field => Search::FacetBuilder.call(field:, alpha_sort:, limit:, facet_prefix: prefix, page:)
      }
    end

    def prefix
      return '1|' if value.nil?

      "#{HierarchicalValueSupport.level(value) + 1}|#{value}"
    end
  end
end
