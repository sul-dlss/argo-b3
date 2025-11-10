# frozen_string_literal: true

module SearchResults
  # Represents facet counts from a Solr response
  class FacetCount
    attr_reader :value, :count

    # @param value [String] the facet value
    # @param count [Integer] the count of items with this facet value
    def initialize(value:, count:)
      @value = value
      @count = count
    end
  end
end
