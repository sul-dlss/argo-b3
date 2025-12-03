# frozen_string_literal: true

module Searchers
  # Searcher for a hierarchical facet
  class HierarchicalFacet
    def self.call(...)
      new(...).call
    end

    # @param search_form [SearchForm]
    # @param facet_config [Search::Facets::FacetConfig] configuration for the facet
    # @param value [String, nil] the facet value to return children for. If nil, returns top-level values
    # @param limit [Integer, nil] maximum number of facet values to return
    # @param page [Integer, nil] optional page number for paged facets
    def initialize(search_form:, facet_config:, value: nil, limit: nil, page: nil)
      @search_form = search_form
      @facet_config = facet_config
      @value = value
      @limit = limit || facet_config.limit
      @page = page
    end

    # @return [SearchResults::FacetCounts] search results
    def call
      SearchResults::HierarchicalFacetCounts.new(solr_response:, facet_config:)
    end

    private

    attr_reader :search_form, :facet_config, :limit, :value, :page

    delegate :alpha_sort, to: :facet_config

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

    def field
      facet_config.hierarchical_field
    end
  end
end
