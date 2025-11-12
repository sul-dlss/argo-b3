# frozen_string_literal: true

module SearchResults
  # Search results for facet counts (value and count)
  class FacetCounts
    include Enumerable

    def initialize(solr_response:, field:)
      @solr_response = solr_response
      @field = field
    end

    # @yield [SearchResults::FacetCount] each facet count
    def each(&)
      return enum_for(:each) unless block_given?

      facet_result = @solr_response['facet_counts']['facet_fields'][field]
      facet_result.each_slice(2) do |value, count|
        yield FacetCount.new(value:, count:)
      end
    end

    def to_ary
      to_a
    end

    attr_reader :solr_response, :field
  end
end
