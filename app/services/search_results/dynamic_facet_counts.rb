# frozen_string_literal: true

module SearchResults
  # Search results for facet counts (value and count) from dynamic facets (i.e., a query for each facet value)
  class DynamicFacetCounts
    include Enumerable

    def initialize(solr_response:, facet_config:)
      @solr_response = solr_response
      @facet_config = facet_config
    end

    # @yield [SearchResults::FacetCount] each facet count
    def each(&)
      return enum_for(:each) unless block_given?

      dynamic_facet.each_key do |key|
        count = solr_response.dig('facets', "#{form_field}-#{key}", 'count')
        next if count.nil?

        yield FacetCount.new(value: key.to_s, count:)
      end
    end

    def to_ary
      to_a
    end

    attr_reader :solr_response, :facet_config

    delegate :dynamic_facet, :form_field, to: :facet_config
  end
end
