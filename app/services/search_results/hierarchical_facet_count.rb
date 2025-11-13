# frozen_string_literal: true

module SearchResults
  # Represents hierarchical facet counts from a Solr response
  class HierarchicalFacetCount
    attr_reader :value, :count, :level, :leaf_or_branch_indicator

    # @param value [String] the facet value
    # @param count [Integer] the count of items with this facet value
    def initialize(value:, count:)
      # Hierarchical values have the format: [LEVEL]|[WORKFLOW DATA]|[LEAF OR BRANCH]
      # For example: "3|accessionWF:start-accession:completed|-"
      @level, @value, @leaf_or_branch_indicator = HierarchicalValueSupport.split(value)
      @count = count
    end

    def leaf?
      leaf_or_branch_indicator == '-'
    end

    def branch?
      !leaf?
    end

    def value_parts
      HierarchicalValueSupport.value_parts(value)
    end
  end
end
