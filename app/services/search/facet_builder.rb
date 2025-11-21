# frozen_string_literal: true

module Search
  # Builds facet parameters for Solr JSON Facet API
  # See https://solr.apache.org/guide/8_11/json-facet-api.html
  class FacetBuilder
    def self.call(...)
      new(...).call
    end

    # @param field [String] the Solr field to facet on
    # @param alpha_sort [Boolean] whether to sort facet values alphabetically
    # @param limit [Integer, nil] maximum number of facet values to return
    # @param facet_prefix [String, nil] optional prefix to filter facet values
    # @param exclude [Boolean] whether to exclude a tagged filter
    # @param page [Integer, nil] optional page number for paged facets
    def initialize(field:, alpha_sort: false, limit: nil, facet_prefix: nil, exclude: false, page: nil) # rubocop:disable Metrics/ParameterLists
      @field = field
      @alpha_sort = alpha_sort
      @limit = limit
      @facet_prefix = facet_prefix
      @exclude = exclude
      @page = page
    end

    def call # rubocop:disable Metrics/AbcSize
      {
        type: 'terms',
        field:,
        sort: (alpha_sort ? 'index' : 'count'),
        numBuckets: true
      }.tap do |facet|
        facet[:limit] = limit if limit
        facet[:prefix] = facet_prefix if facet_prefix.present?
        # Exclude means that there is a tagged filter that should be ignored when calculating the facet.
        # Tagging is done in ItemQueryBuilder.
        # This is useful for checkbox facets (in all values for the facet should be returned).
        # See https://solr.apache.org/guide/8_11/json-faceting-domain-changes.html#filter-exclusions
        facet[:domain] = { excludeTags: [field] } if exclude
        facet[:offset] = (page - 1) * limit if page && limit
      end
    end

    private

    attr_reader :field, :alpha_sort, :limit, :facet_prefix, :exclude, :page
  end
end
