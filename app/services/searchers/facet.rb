# frozen_string_literal: true

module Searchers
  # Searcher for a basic facet
  class Facet
    include Search::Fields

    def self.call(...)
      new(...).call
    end

    # @param search_form [Search::ItemForm]
    def initialize(search_form:, field:)
      @search_form = search_form
      @field = field
    end

    # @return [SearchResults::FacetCounts] search results
    def call
      SearchResults::FacetCounts.new(solr_response:, field:)
    end

    private

    attr_reader :search_form, :field

    def solr_response
      Search::SolrService.call(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:).merge(
        {
          facet: true,
          'facet.field': [field],
          rows: 0
        }
      )
    end
  end
end
