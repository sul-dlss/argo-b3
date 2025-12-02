# frozen_string_literal: true

module SearchResults
  # Search results for items (DROs, collections, or APOs)
  class Items
    include Enumerable

    def initialize(solr_response:, per_page:)
      @solr_response = solr_response
      @per_page = per_page
    end

    # @yield [SearchResult::Item] each item
    def each(&)
      return enum_for(:each) unless block_given?

      @solr_response['response']['docs'].each.with_index(1) do |solr_doc, index|
        yield Item.new(solr_doc:, index: index + start_result)
      end
    end

    def total_results
      @solr_response['response']['numFound']
    end

    def page
      (start_result / per_page) + 1
    end

    def total_pages
      (total_results.to_f / per_page).ceil
    end

    attr_reader :solr_response, :per_page

    def to_ary
      to_a
    end

    # Derive a getter method for facets, when the "[facet_config]_facet" method is called.
    # For example, object_types_facet() is handled equivalent to defining:
    # def object_types_facet
    #   FacetCounts.new(solr_response:, field: Search::Fields::OBJECT_TYPES)
    # end
    def method_missing(method_name, *, &)
      return super unless respond_to_missing?(method_name)

      facet_config = Search::Facets.const_get(method_name_to_const_name(method_name))
      # Different facet count classes are needed depending on the facet type.
      clazz = facet_config.dynamic_facet.present? ? DynamicFacetCounts : FacetCounts
      clazz.new(solr_response:, facet_config:)
    end

    def respond_to_missing?(method_name, include_private = false)
      return false unless method_name.to_s.end_with?('_facet')

      Search::Facets.const_defined?(method_name_to_const_name(method_name)) || super
    end

    private

    def method_name_to_const_name(method_name)
      method_name.to_s.delete_suffix('_facet').upcase
    end

    def start_result
      @solr_response['response']['start']
    end
  end
end
