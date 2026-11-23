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

      yield missing_value_facet_count if show_missing_value?
      bucket_facet_counts.each(&)
      # Selected values that aren't among the top values follow them on the first page.
      selected_facet_counts.each(&) if offset.zero?
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

    # "No value" is shown first, so only on the first page.
    def show_missing_value?
      facet_config.missing_value && offset.zero? && missing_value_count.positive?
    end

    def missing_value_count
      facet_result.dig('missing', 'count') || 0
    end

    def missing_value_facet_count
      FacetCount.new(value: Search::Facets::MISSING_VALUE, label: I18n.t('search.facet_values._missing_value'),
                     count: missing_value_count)
    end

    def bucket_facet_counts
      facet_result['buckets'].map do |bucket|
        value, label = bucket_value_and_label(bucket['val'])
        FacetCount.new(value:, label:, count: bucket['count'])
      end
    end

    def selected_facet_counts
      return [] if selected_result.nil?

      bucket_values = bucket_facet_counts.map(&:value)
      selected_values.each_with_index.filter_map do |value, index|
        next if bucket_values.include?(value)

        value_result = selected_result[index.to_s] || {}
        FacetCount.new(value:, label: selected_label(value, value_result), count: value_result['count'] || 0)
      end
    end

    def selected_key
      Search::SelectedFacetValuesBuilder.key(facet_config)
    end

    def selected_result
      solr_response['facets'][selected_key]
    end

    # The values, in the order of their keys, from the queries in the request.
    def selected_values
      request_facets = JSON.parse(solr_response['responseHeader']['params']['json.facet'])
      request_facets.dig(selected_key, 'facet').values.map do |value_facet|
        Search::SelectedFacetValuesBuilder.value_from(facet_config:, query: value_facet['q'])
      end
    end

    def selected_label(value, value_result)
      return value unless facet_config.composite_facet_field

      buckets = value_result.dig('labels', 'buckets') || []
      composite = buckets.map { |bucket| Search::CompositeFacetValue.parse(bucket['val']) }.find { |id, _| id == value }
      composite&.last || value
    end

    def bucket_value_and_label(val)
      return [val, val] unless facet_config.composite_facet_field

      Search::CompositeFacetValue.parse(val)
    end
  end
end
