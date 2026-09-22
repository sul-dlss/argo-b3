# frozen_string_literal: true

module SearchResults
  # Search results for facet counts (value and count).
  # This handles results from a facet query (standard Solr faceting) rather than JSON Facet API.
  class FacetQueryCounts
    include Enumerable

    def initialize(solr_response:, facet_config:)
      @solr_response = solr_response
      @facet_config = facet_config
    end

    # @yield [SearchResults::FacetCount] each facet count
    def each(&)
      return enum_for(:each) unless block_given?

      facet_result = @solr_response['facet_counts']['facet_fields'][field]
      facet_result.each_slice(2) do |val, count|
        value, label = bucket_value_and_label(val)
        yield FacetCount.new(value:, label:, count:)
      end
    end

    def to_ary
      to_a
    end

    attr_reader :solr_response, :facet_config

    private

    def field
      facet_config.facet_field
    end

    def bucket_value_and_label(val)
      return [val, val] unless facet_config.composite_facet_field

      Search::CompositeFacetValue.parse(val)
    end
  end
end
