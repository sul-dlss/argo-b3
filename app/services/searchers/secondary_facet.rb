# frozen_string_literal: true

module Searchers
  # Searcher for secondary facets
  class SecondaryFacet
    FACETS = [
      Search::Facets::ACCESS_RIGHTS,
      Search::Facets::ADMIN_POLICIES,
      Search::Facets::COLLECTIONS,
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

    # @param search_form [SearchForm]
    def initialize(search_form:)
      @search_form = search_form
    end

    # @return [SearchResults::Items] search results
    def call
      SearchResults::Items.new(solr_response:, per_page: 0)
    end

    private

    attr_reader :search_form

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:).merge(
        {
          rows: 0,
          'json.facet': facet_json
        }
      )
    end

    def facet_json
      Search::FacetsBuilder.call(facet_configs: FACETS).to_json
    end
  end
end
