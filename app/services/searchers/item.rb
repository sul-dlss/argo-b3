# frozen_string_literal: true

module Searchers
  # Searcher for items (DROs, collections, or APOs)
  class Item
    include Search::Fields

    PER_PAGE = 20

    def self.call(...)
      new(...).call
    end

    # @param search_form [Search::ItemForm]
    def initialize(search_form:)
      @search_form = search_form
    end

    # @return [SearchResults::Items] search results
    def call
      SearchResults::Items.new(solr_response:, per_page: PER_PAGE)
    end

    private

    attr_reader :search_form

    def solr_response
      Search::SolrService.call(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:).merge(
        {
          fl: [ID, TITLE, BARE_DRUID],
          facet: true,
          # These are fast (non-lazy) facets
          'facet.field' => [],
          rows:,
          start:
        }.tap do |req|
          add_facet(req, field: OBJECT_TYPE, exclude: true)
          add_facet(req, field: ACCESS_RIGHTS, limit: 50, alpha_sort: true)
        end
      )
    end

    def rows
      search_form.blank? ? 0 : PER_PAGE
    end

    def start
      (search_form.page - 1) * rows
    end

    # @param request [Hash] the Solr request being built
    # @param field [String] the Solr field to facet on
    # @param alpha_sort [Boolean] whether to sort facet values alphabetically
    # @param limit [Integer, nil] maximum number of facet values to return
    # @param exclude [Boolean] whether to exclude a tagged filter
    def add_facet(request, field:, alpha_sort: false, limit: nil, exclude: false)
      # Exclude means that there is a tagged filter that should be ignored when calculating the facet.
      # Tagging is done in ItemQueryBuilder.
      # This is useful for checkbox facets (in all values for the facet should be returned).
      # See https://solr.apache.org/guide/8_11/faceting.html#tagging-and-excluding-filters
      request['facet.field'] << (exclude ? "{!ex=#{field}}#{field}" : field)
      request["f.#{field}.facet.sort"] = 'index' if alpha_sort
      request["f.#{field}.facet.limit"] = limit if limit
    end
  end
end
