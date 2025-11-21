# frozen_string_literal: true

module SearchResults
  # Search results for hierarchical facet counts (value and count)
  class HierarchicalFacetCounts < FacetCounts
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

      # facet_result = solr_response['facet_counts']['facet_fields'][field]
      # Given facet_result=[{val:"1|foo|+", count:5}, {val:"1|foo|-", count:2}, {val:"1|bar|+", count:3}]
      return if facet_result.nil?

      grouped_facet_results = facet_result['buckets'].group_by { |bucket| bucket['val'].rpartition('|').first }
      # grouped_facet_results={"1|foo" => [{val:"1|foo|+", count:5},
      #   {val:"1|foo|-", count:2}], "1|bar" => [{val:"1|bar|+", count:3}]}

      grouped_facet_results.each do |level_and_facet_value, grouped_values_and_counts|
        if grouped_values_and_counts.size == 1
          value = grouped_values_and_counts[0]['val']
          count = grouped_values_and_counts[0]['count']
        else
          value = "#{level_and_facet_value}|+"
          count = grouped_values_and_counts.sum { |bucket| bucket['count'] }
        end
        yield HierarchicalFacetCount.new(value:, count:)
      end
    end
  end
end
