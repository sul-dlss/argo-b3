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

      @solr_response['response']['docs'].each do |solr_doc|
        yield Item.new(solr_doc:)
      end
    end

    def object_type_facet
      FacetCounts.new(solr_response:, field: Search::Fields::OBJECT_TYPE)
    end

    def access_rights_facet
      FacetCounts.new(solr_response:, field: Search::Fields::ACCESS_RIGHTS)
    end

    def mimetypes_facet
      FacetCounts.new(solr_response:, field: Search::Fields::MIMETYPES)
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

    private

    def start_result
      @solr_response['response']['start']
    end
  end
end
