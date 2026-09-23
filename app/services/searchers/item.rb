# frozen_string_literal: true

module Searchers
  # Searcher for items (DROs, collections, or APOs)
  class Item
    PER_PAGE = 50

    # fl fields to request from Solr
    FIELD_LIST = [
      Search::Fields::ACCESS_RIGHTS,
      Search::Fields::APO_DRUID,
      Search::Fields::APO_TITLE,
      Search::Fields::AUTHOR,
      Search::Fields::BARE_DRUID,
      Search::Fields::CATALOG_RECORD_ID,
      Search::Fields::COLLECTION_DRUIDS,
      Search::Fields::COLLECTION_TITLES,
      Search::Fields::CONTENT_TYPES,
      Search::Fields::ID,
      Search::Fields::ALL_TAGS,
      Search::Fields::OBJECT_TYPES,
      Search::Fields::PROJECTS,
      Search::Fields::PUBLICATION_DATE,
      Search::Fields::PUBLICATION_PLACE,
      Search::Fields::PUBLISHER,
      Search::Fields::SOURCE_ID,
      Search::Fields::RELEASED_TO,
      Search::Fields::STATUS,
      Search::Fields::TICKETS,
      Search::Fields::TITLE,
      Search::Fields::WORKFLOW_ERRORS,
      Search::Fields::FIRST_SHELVED_IMAGE
    ].freeze

    # Primary facets that are included in the main item search request
    FACETS = [
      Search::Facets::CONTENT_TYPES,
      Search::Facets::OBJECT_TYPES
    ].freeze

    def self.call(...)
      new(...).call
    end

    # @param search_form [SearchForm]
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    def initialize(search_form:, user_scope:)
      @search_form = search_form
      @user_scope = user_scope
    end

    # @return [SearchResults::Items] search results
    def call
      SearchResults::Items.new(solr_response:, per_page: PER_PAGE)
    end

    private

    attr_reader :search_form, :user_scope

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:, user_scope:).merge(
        {
          fl: FIELD_LIST,
          rows: PER_PAGE,
          start:,
          sort:,
          'json.facet': facet_json
        }
      )
    end

    def facet_json
      Search::FacetsBuilder.call(facet_configs: FACETS).to_json
    end

    # @return [String, nil] Solr sort value or nil if none
    def sort
      Search::SortOptions.find_config_by_sort_field(search_form.sort)&.sort_value
    end

    def start
      (search_form.page - 1) * PER_PAGE
    end
  end
end
