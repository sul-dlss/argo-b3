# frozen_string_literal: true

module SearchResults
  # Represents facet counts from a Solr response
  class FacetCount
    attr_reader :value, :count, :label

    # @param value [String] the facet value
    # @param count [Integer] the count of items with this facet value
    # @param label [String] the display label for this facet value; defaults to the value itself
    def initialize(value:, count:, label: value)
      @value = value
      @count = count
      @label = label
    end
  end
end
