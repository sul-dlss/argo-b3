# frozen_string_literal: true

module Searchers
  # Searcher for items (DROs, collections, or APOs)
  class Item
    PER_PAGE = 20

    # fl fields to request from Solr
    FIELD_LIST = [
      Search::Fields::ACCESS_RIGHTS,
      Search::Fields::APO_DRUID,
      Search::Fields::APO_TITLE,
      Search::Fields::BARE_DRUID,
      Search::Fields::CONTENT_TYPES,
      Search::Fields::ID,
      Search::Fields::IDENTIFIERS,
      Search::Fields::OBJECT_TYPES,
      Search::Fields::PROJECTS,
      Search::Fields::SOURCE_ID,
      Search::Fields::RELEASED_TO,
      Search::Fields::STATUS,
      Search::Fields::TICKETS,
      Search::Fields::TITLE,
      Search::Fields::WORKFLOW_ERRORS
    ].freeze

    FACETS = [
      Search::Facets::ACCESS_RIGHTS,
      Search::Facets::ADMIN_POLICIES,
      Search::Facets::COLLECTIONS,
      Search::Facets::CONTENT_TYPES,
      Search::Facets::DATES,
      Search::Facets::EARLIEST_ACCESSIONED_DATE,
      Search::Facets::EMBARGO_RELEASE_DATE,
      Search::Facets::FILE_ROLES,
      Search::Facets::GENRES,
      Search::Facets::IDENTIFIERS,
      Search::Facets::LANGUAGES,
      Search::Facets::LAST_ACCESSIONED_DATE,
      Search::Facets::LAST_PUBLISHED_DATE,
      Search::Facets::LAST_OPENED_DATE,
      Search::Facets::LICENSES,
      Search::Facets::METADATA_SOURCES,
      Search::Facets::MIMETYPES,
      Search::Facets::MODS_RESOURCE_TYPES,
      Search::Facets::OBJECT_TYPES,
      Search::Facets::PROCESSING_STATUSES,
      Search::Facets::REGIONS,
      Search::Facets::REGISTERED_DATE,
      Search::Facets::RELEASED_TO_EARTHWORKS,
      Search::Facets::RELEASED_TO_PURL_SITEMAP,
      Search::Facets::RELEASED_TO_SEARCHWORKS,
      Search::Facets::SW_RESOURCE_TYPES,
      Search::Facets::TOPICS,
      Search::Facets::VERSIONS
    ].freeze

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
          fl: FIELD_LIST,
          rows:,
          start:,
          'json.facet': facet_json.to_json
        }
      )
    end

    def facet_json
      FACETS.each_with_object({}) do |facet_config, facet_hash|
        if facet_config.dynamic_facet.present?
          facet_hash.merge!(Search::DynamicFacetBuilder.call(**facet_config.to_h.slice(:form_field, :dynamic_facet)))
        else
          facet_hash[facet_config.field] =
            Search::FacetBuilder.call(**facet_config.to_h.slice(:field, :limit, :alpha_sort, :exclude))
        end
      end
    end

    def rows
      search_form.blank? ? 0 : PER_PAGE
    end

    def start
      (search_form.page - 1) * rows
    end
  end
end
