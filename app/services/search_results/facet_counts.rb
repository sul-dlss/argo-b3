# frozen_string_literal: true

module SearchResults
  # Search results for facet counts (value and count)
  class FacetCounts
    include Enumerable

    def initialize(solr_response:, facet_config:)
      @solr_response = solr_response
      @facet_config = facet_config
    end

    # @yield [SearchResults::FacetCount] each facet count
    def each(&)
      return enum_for(:each) unless block_given?

      return if facet_result.nil?

      facet_result['buckets'].each do |bucket|
        value, label = bucket_value_and_label(bucket['val'])
        yield FacetCount.new(value:, label:, count: bucket['count'])
      end
    end

    def to_ary
      to_a
    end

    def total_facets
      return 0 if facet_result.nil?

      facet_result['numBuckets']
    end

    def page
      (offset / per_page) + 1
    end

    def total_pages
      (total_facets.to_f / per_page).ceil
    end

    attr_reader :solr_response, :facet_config

    def facet_result
      @solr_response['facets'][field]
    end

    def json_facet
      @json_facet ||= JSON.parse(@solr_response['responseHeader']['params']['json.facet'])[field]
    end

    def per_page
      @per_page ||= json_facet['limit']
    end

    def offset
      @offset ||= json_facet['offset'] || 0
    end

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
