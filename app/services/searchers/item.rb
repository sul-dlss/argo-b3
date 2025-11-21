# frozen_string_literal: true

module Searchers
  # Searcher for items (DROs, collections, or APOs)
  class Item
    include Search::Fields

    PER_PAGE = 20
    # Attributes of Search::Facets::Config to be passed to Search::FacetBuilder
    FACET_BUILDER_ARGS = %i[limit alpha_sort exclude].freeze

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
          rows:,
          start:,
          'json.facet': facet_json.to_json
        }
      )
    end

    def facet_json
      # These are fast (non-lazy) facets
      {
        OBJECT_TYPE => Search::FacetBuilder.call(field: OBJECT_TYPE, **Search::Facets::OBJECT_TYPES.to_h.slice(*FACET_BUILDER_ARGS)),
        ACCESS_RIGHTS => Search::FacetBuilder.call(field: ACCESS_RIGHTS, **Search::Facets::ACCESS_RIGHTS.to_h.slice(*FACET_BUILDER_ARGS)),
        MIMETYPES => Search::FacetBuilder.call(field: MIMETYPES, **Search::Facets::MIMETYPES.to_h.slice(*FACET_BUILDER_ARGS))
      }
    end

    def rows
      search_form.blank? ? 0 : PER_PAGE
    end

    def start
      (search_form.page - 1) * rows
    end
  end
end
