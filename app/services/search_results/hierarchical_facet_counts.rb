# frozen_string_literal: true

module SearchResults
  # Search results for hierarchical facet counts (value and count)
  class HierarchicalFacetCounts
    include Enumerable

    def initialize(solr_response:, field:)
      @solr_response = solr_response
      @field = field
    end

    # @yield [SearchResults::FacetCount] each facet count
    def each(&) # rubocop:disable Metrics/AbcSize
      return enum_for(:each) unless block_given?

      # In order to lazily render hierarchical facets, it needs to be known if a
      # particular value has children (that is, is a branch).
      # Each facet value is stored in Solr as [LEVEL]|[VALUE PARTS...]|[+ if branch, - if leaf]
      # For example, "2|Foo|Bar|+" is a branch at level 2 with value parts "Foo" and "Bar".
      # However, it is possible that there is both a leaf and a branch at the same level and value parts,
      # For example, "2|Foo|Bar|+" and "2|Foo|Bar|-".
      # These should only be yielded once, with the count being the sum of both.
      # When there is a branch and a leaf at the same level and value parts,
      # the branch should be used (with the "+" suffix).
      facet_result = solr_response['facet_counts']['facet_fields'][field]
      # Given facet_result=["1|foo|+", 5, "1|foo|-", 2, '1|bar|+', 3]

      grouped_facet_results = facet_result.each_slice(2).group_by { |value, _count| value.rpartition('|').first }
      # grouped_facet_results={"1|foo" => [["1|foo|+", 5], ["1|foo|-", 2]], "1|bar" => [["1|bar|+", 3]]}

      grouped_facet_results.each do |level_and_facet_value, grouped_values_and_counts|
        if grouped_values_and_counts.size == 1
          value, count = grouped_values_and_counts[0]
        else
          value = "#{level_and_facet_value}|+"
          count = grouped_values_and_counts.sum { |_value, count| count }
        end
        yield HierarchicalFacetCount.new(value:, count:)
      end
    end

    def to_ary
      to_a
    end

    attr_reader :solr_response, :field
  end
end
