# frozen_string_literal: true

module Searchers
  # Searcher for items (DROs, collections, or APOs)
  class Item
    include Search::Fields

    PER_PAGE = 20

    def self.call(...)
      new(...).call
    end

    # @param search_form [Search::ItemForm]
    def initialize(search_form:)
      @search_form = search_form
    end

    # @return [SearchResults::Items] search results
    def call
      SearchResults::Items.new(solr_response:, per_page: PER_PAGE)
    end

    private

    attr_reader :search_form

    def solr_response
      Search::SolrService.call(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:).merge(
        {
          fl: [ID, TITLE, BARE_DRUID],
          facet: true,
          # These are fast (non-lazy) facets
          'facet.field': [OBJECT_TYPE],
          rows:,
          start:
        }
      )
    end

    def rows
      search_form.blank? ? 0 : PER_PAGE
    end

    def start
      (search_form.page - 1) * rows
    end
  end
end
