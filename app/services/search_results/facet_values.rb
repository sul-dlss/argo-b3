# frozen_string_literal: true

module SearchResults
  # Search results for facet values, e.g., project tags
  class FacetValues
    include Enumerable

    def initialize(solr_response:, field:)
      @solr_response = solr_response
      @field = field
    end

    # @yield [String] each facet value
    def each(&)
      return enum_for(:each) unless block_given?

      facet_result = @solr_response['facet_counts']['facet_fields'][field]
      facet_result.each_slice(2) do |value, _count|
        yield value
      end
    end

    def to_ary
      to_a
    end

    attr_reader :solr_response, :field
  end
end
