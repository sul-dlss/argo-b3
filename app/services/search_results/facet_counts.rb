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

      return if facet_result.nil?

      facet_result['buckets'].each do |bucket|
        yield FacetCount.new(value: bucket['val'], count: bucket['count'])
      end
    end

    def to_ary
      to_a
    end

    def total_facets
      facet_result['numBuckets']
    end

    attr_reader :solr_response, :field

    def facet_result
      @solr_response['facets'][field]
    end
  end
end
