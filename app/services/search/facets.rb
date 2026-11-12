# frozen_string_literal: true

module Search
  # Constants for facet configuration
  module Facets # rubocop:disable Metrics/ModuleLength
    def self.find_config_by_form_field(form_field)
      ALL.find { |config| config.form_field == form_field.to_sym }
    end

    def self.missing_value?(value)
      value == MISSING_VALUE
    end

    Config = Struct.new('FacetConfig',
                        :form_field,
                        # How the sidebar loads the facet (see SIDEBAR): :primary, :secondary, :lazy, or nil.
                        :loading,
                        # Provide if this facet supports excluding values.
                        :exclude_form_field,
                        # True to sort alphabetically, otherwise sort by count.
                        :alpha_sort,
                        :limit,
                        # Solr field.
                        :field,
                        # Solr hierarchical field containing the exploded hierarchy. Only for hierarchical facets.
                        :hierarchical_field,
                        # Form field for the from/to dates in a date range facet.
                        :date_from_form_field,
                        :date_to_form_field,
                        # The routing resource that serves this facet's endpoints, e.g. :tag_facets.
                        # Routes are drawn from this (see ROUTED) and served by Search::FacetsController.
                        # Path helpers are resolved from this plus the search form's route scope.
                        # See Search::FacetPathResolver.
                        :facet_resource,
                        # True if the facet has an index endpoint.
                        # This is used for a lazy facet and/or a pageable facet.
                        # If true and the number of facet values exceeds the limit, paging will be enabled.
                        :facet_index,
                        # True if the facet has a children endpoint. Only for hierarchical facets.
                        :facet_children,
                        # True if the facet has a search endpoint. If true, search will be enabled.
                        :facet_search,
                        # How multiple selected values for the facet are combined: :and or :or.
                        # An :or facet's counts ignore the facet's own selection (see FacetBuilder), so that all
                        # of its values remain selectable. This is used, for example, for a checkbox facet.
                        :operator,
                        # Hash of dynamic facet keys to Solr queries.
                        # This is used for facets like released_to_earthworks.
                        :dynamic_facet,
                        # True to offer a "No value" option for objects without a value for the field.
                        :missing_value,
                        # `composite_facet_field` is a solr field whose values encode "<label>:<id>"
                        # (see Search::CompositeFacetValue), where the id is a druid or a URI,
                        # e.g. "Stanford Theses:druid:bc123df4567" or
                        # "CC Zero 1.0:https://creativecommons.org/publicdomain/zero/1.0/legalcode".
                        # Set this when a facet needs to filter on an identifier (eg druid) but display and
                        # text-search a human-readable label (eg object title). Since a title alone isn't unique
                        # faceting on the display label directly (like most facets do) is ambiguous for
                        # objects with a shared title.
                        :composite_facet_field) do
      # @return [String] the Solr field to facet/search on
      def facet_field
        composite_facet_field || field
      end

      # Loaded by its own turbo frame request rather than with a search request.
      def lazy?
        loading == :lazy
      end

      def hierarchical?
        hierarchical_field.present?
      end
    end

    # Facet value for selecting objects without a value for the field (see Config#missing_value).
    MISSING_VALUE = '_missing_value'

    def Config.with_defaults(**)
      defaults = { alpha_sort: false, limit: 100, operator: :and,
                   facet_index: false, facet_children: false, facet_search: false, missing_value: false }
      new(**defaults, **)
    end

    ACCESS_RIGHTS = Config.with_defaults(
      form_field: :access_rights,
      loading: :secondary,
      field: Search::Fields::ACCESS_RIGHTS,
      exclude_form_field: :access_rights_exclude,
      limit: 50,
      alpha_sort: true
    )

    # Facets and filters on the druid (a title is not a unique identifier), but displays the title
    # via the composite field. Also used for direct links from the APO show page for items/collections
    # governed by the APO.
    ADMIN_POLICIES = Config.with_defaults(
      form_field: :admin_policy_druids,
      loading: :secondary,
      field: Search::Fields::APO_DRUID,
      composite_facet_field: Search::Fields::APO_TITLE_DRUID,
      limit: 25,
      facet_resource: :admin_policy_facets,
      facet_index: true,
      facet_search: true,
      alpha_sort: true
    )

    # Facets and filters on the druid (a title is not a unique identifier), but displays the title
    # via the composite field. Also used for direct links from the Collection show page for items
    # in the collection.
    COLLECTIONS = Config.with_defaults(
      form_field: :collection_druids,
      loading: :secondary,
      field: Search::Fields::COLLECTION_DRUIDS,
      composite_facet_field: Search::Fields::COLLECTION_TITLE_DRUIDS,
      limit: 25,
      facet_resource: :collection_facets,
      facet_index: true,
      facet_search: true,
      alpha_sort: true
    )

    CONTENT_TYPES = Config.with_defaults(
      form_field: :content_types,
      loading: :primary,
      field: Search::Fields::CONTENT_TYPES,
      limit: 25,
      operator: :or
    )

    DATES = Config.with_defaults(
      form_field: :dates,
      loading: :secondary,
      field: Search::Fields::PUBLICATION_DATE,
      limit: 25,
      facet_resource: :date_facets,
      facet_index: true,
      facet_search: true,
      missing_value: true
    )

    FILE_ROLES = Config.with_defaults(
      form_field: :file_roles,
      loading: :secondary,
      field: Search::Fields::FILE_ROLES,
      limit: 20,
      operator: :or
    )

    GENRES = Config.with_defaults(
      form_field: :genres,
      loading: :secondary,
      field: Search::Fields::GENRES,
      limit: 25,
      facet_resource: :genre_facets,
      facet_index: true,
      facet_search: true,
      missing_value: true
    )

    EARLIEST_ACCESSIONED_DATE = Config.with_defaults(
      form_field: :earliest_accessioned_date,
      loading: :secondary,
      date_from_form_field: :earliest_accessioned_date_from,
      date_to_form_field: :earliest_accessioned_date_to,
      field: Search::Fields::EARLIEST_ACCESSIONED_DATE,
      dynamic_facet: {
        today: "#{Search::Fields::EARLIEST_ACCESSIONED_DATE}:#{Search::Queries::TODAY}",
        last_7_days: "#{Search::Fields::EARLIEST_ACCESSIONED_DATE}:#{Search::Queries::LAST_7_DAYS}",
        last_30_days: "#{Search::Fields::EARLIEST_ACCESSIONED_DATE}:#{Search::Queries::LAST_30_DAYS}",
        year_to_date: "#{Search::Fields::EARLIEST_ACCESSIONED_DATE}:#{Search::Queries::YEAR_TO_DATE}",
        all: "#{Search::Fields::EARLIEST_ACCESSIONED_DATE}:#{Search::Queries::ALL}"
      }
    )

    EMBARGO_RELEASE_DATE = Config.with_defaults(
      form_field: :embargo_release_date,
      loading: :secondary,
      date_from_form_field: :embargo_release_date_from,
      date_to_form_field: :embargo_release_date_to,
      field: Search::Fields::EMBARGO_RELEASE_DATE,
      dynamic_facet: {
        next_7_days: "#{Search::Fields::EMBARGO_RELEASE_DATE}:#{Search::Queries::NEXT_7_DAYS}",
        next_30_days: "#{Search::Fields::EMBARGO_RELEASE_DATE}:#{Search::Queries::NEXT_30_DAYS}",
        next_year: "#{Search::Fields::EMBARGO_RELEASE_DATE}:#{Search::Queries::NEXT_YEAR}",
        all: "#{Search::Fields::EMBARGO_RELEASE_DATE}:#{Search::Queries::ALL}"
      }
    )

    ERROR_DATE = Config.with_defaults(
      form_field: :error_date,
      loading: :secondary,
      date_from_form_field: :error_date_from,
      date_to_form_field: :error_date_to,
      field: Search::Fields::LAST_WORKFLOW_ERROR_DATE,
      dynamic_facet: {
        today: "#{Search::Fields::LAST_WORKFLOW_ERROR_DATE}:#{Search::Queries::TODAY}",
        last_7_days: "#{Search::Fields::LAST_WORKFLOW_ERROR_DATE}:#{Search::Queries::LAST_7_DAYS}",
        last_30_days: "#{Search::Fields::LAST_WORKFLOW_ERROR_DATE}:#{Search::Queries::LAST_30_DAYS}",
        year_to_date: "#{Search::Fields::LAST_WORKFLOW_ERROR_DATE}:#{Search::Queries::YEAR_TO_DATE}",
        all: "#{Search::Fields::LAST_WORKFLOW_ERROR_DATE}:#{Search::Queries::ALL}"
      }
    )

    IDENTIFIERS = Config.with_defaults(
      form_field: :identifiers,
      loading: :secondary,
      dynamic_facet: {
        has_orcids: "+#{Search::Fields::ORCIDS}:*",
        has_doi: "+#{Search::Fields::DOI}:*",
        has_barcode: "+#{Search::Fields::BARCODES}:*"
      }
    )

    LANGUAGES = Config.with_defaults(
      form_field: :languages,
      loading: :secondary,
      field: Search::Fields::LANGUAGES,
      limit: 25,
      facet_resource: :language_facets,
      facet_index: true,
      facet_search: true,
      missing_value: true
    )

    LAST_ACCESSIONED_DATE = Config.with_defaults(
      form_field: :last_accessioned_date,
      loading: :secondary,
      date_from_form_field: :last_accessioned_date_from,
      date_to_form_field: :last_accessioned_date_to,
      field: Search::Fields::LAST_ACCESSIONED_DATE,
      dynamic_facet: {
        today: "#{Search::Fields::LAST_ACCESSIONED_DATE}:#{Search::Queries::TODAY}",
        last_7_days: "#{Search::Fields::LAST_ACCESSIONED_DATE}:#{Search::Queries::LAST_7_DAYS}",
        last_30_days: "#{Search::Fields::LAST_ACCESSIONED_DATE}:#{Search::Queries::LAST_30_DAYS}",
        year_to_date: "#{Search::Fields::LAST_ACCESSIONED_DATE}:#{Search::Queries::YEAR_TO_DATE}",
        all: "#{Search::Fields::LAST_ACCESSIONED_DATE}:#{Search::Queries::ALL}"
      }
    )

    LAST_OPENED_DATE = Config.with_defaults(
      form_field: :last_opened_date,
      loading: :secondary,
      date_from_form_field: :last_opened_date_from,
      date_to_form_field: :last_opened_date_to,
      field: Search::Fields::LAST_OPENED_DATE,
      dynamic_facet: {
        today: "#{Search::Fields::LAST_OPENED_DATE}:#{Search::Queries::TODAY}",
        last_7_days: "#{Search::Fields::LAST_OPENED_DATE}:#{Search::Queries::LAST_7_DAYS}",
        last_30_days: "#{Search::Fields::LAST_OPENED_DATE}:#{Search::Queries::LAST_30_DAYS}",
        year_to_date: "#{Search::Fields::LAST_OPENED_DATE}:#{Search::Queries::YEAR_TO_DATE}",
        all: "#{Search::Fields::LAST_OPENED_DATE}:#{Search::Queries::ALL}"
      }
    )

    LAST_PUBLISHED_DATE = Config.with_defaults(
      form_field: :last_published_date,
      loading: :secondary,
      date_from_form_field: :last_published_date_from,
      date_to_form_field: :last_published_date_to,
      field: Search::Fields::LAST_PUBLISHED_DATE,
      dynamic_facet: {
        today: "#{Search::Fields::LAST_PUBLISHED_DATE}:#{Search::Queries::TODAY}",
        last_7_days: "#{Search::Fields::LAST_PUBLISHED_DATE}:#{Search::Queries::LAST_7_DAYS}",
        last_30_days: "#{Search::Fields::LAST_PUBLISHED_DATE}:#{Search::Queries::LAST_30_DAYS}",
        year_to_date: "#{Search::Fields::LAST_PUBLISHED_DATE}:#{Search::Queries::YEAR_TO_DATE}"
      }
    )

    # Facets and filters on the license URI, but displays the license label via the composite field.
    # Filter only; not shown as a facet.
    LAST_UPDATED_BY = Config.with_defaults(
      form_field: :last_updated_by,
      field: Search::Fields::LAST_UPDATED_BY
    )

    LICENSES = Config.with_defaults(
      form_field: :licenses,
      loading: :secondary,
      field: Search::Fields::LICENSE_URI,
      composite_facet_field: Search::Fields::LICENSE_LABEL_URI,
      limit: 50,
      alpha_sort: true,
      missing_value: true
    )

    METADATA_SOURCES = Config.with_defaults(
      form_field: :metadata_sources,
      loading: :secondary,
      field: Search::Fields::METADATA_SOURCE,
      limit: 2
    )

    MIMETYPES = Config.with_defaults(
      form_field: :mimetypes,
      loading: :secondary,
      field: Search::Fields::MIMETYPES,
      limit: 10,
      facet_resource: :mimetype_facets,
      facet_index: true,
      facet_search: true
    )

    MODS_RESOURCE_TYPES = Config.with_defaults(
      form_field: :mods_resource_types,
      loading: :secondary,
      field: Search::Fields::MODS_RESOURCE_TYPES,
      limit: 100,
      missing_value: true
    )

    OBJECT_TYPES = Config.with_defaults(
      form_field: :object_types,
      loading: :primary,
      field: Search::Fields::OBJECT_TYPES,
      operator: :or
    )

    PROCESSING_STATUSES = Config.with_defaults(
      form_field: :processing_statuses,
      loading: :secondary,
      field: Search::Fields::PROCESSING_STATUS,
      limit: 10,
      operator: :or
    )

    PROJECTS = Config.with_defaults(
      form_field: :projects,
      loading: :lazy,
      field: Search::Fields::PROJECTS_EXPLODED,
      hierarchical_field: Search::Fields::PROJECTS_HIERARCHICAL,
      alpha_sort: true,
      limit: 25,
      facet_resource: :project_facets,
      facet_index: true,
      facet_children: true,
      facet_search: true
    )

    REGIONS = Config.with_defaults(
      form_field: :regions,
      loading: :secondary,
      field: Search::Fields::REGIONS,
      limit: 25,
      facet_resource: :region_facets,
      facet_index: true,
      facet_search: true,
      missing_value: true
    )

    REGISTERED_DATE = Config.with_defaults(
      form_field: :registered_date,
      loading: :secondary,
      date_from_form_field: :registered_date_from,
      date_to_form_field: :registered_date_to,
      field: Search::Fields::REGISTERED_DATE,
      dynamic_facet: {
        today: "#{Search::Fields::REGISTERED_DATE}:#{Search::Queries::TODAY}",
        last_7_days: "#{Search::Fields::REGISTERED_DATE}:#{Search::Queries::LAST_7_DAYS}",
        last_30_days: "#{Search::Fields::REGISTERED_DATE}:#{Search::Queries::LAST_30_DAYS}",
        year_to_date: "#{Search::Fields::REGISTERED_DATE}:#{Search::Queries::YEAR_TO_DATE}",
        all: "#{Search::Fields::REGISTERED_DATE}:#{Search::Queries::ALL}"
      }
    )

    TAGS = Config.with_defaults(
      form_field: :tags,
      loading: :lazy,
      field: Search::Fields::OTHER_TAGS_EXPLODED,
      hierarchical_field: Search::Fields::OTHER_HIERARCHICAL_TAGS,
      alpha_sort: true,
      limit: 25,
      facet_resource: :tag_facets,
      facet_index: true,
      facet_children: true,
      facet_search: true
    )

    TICKETS = Config.with_defaults(
      form_field: :tickets,
      loading: :lazy,
      field: Search::Fields::TICKETS,
      alpha_sort: true,
      limit: 25,
      facet_resource: :ticket_facets,
      facet_index: true,
      facet_search: true
    )

    TOPICS = Config.with_defaults(
      form_field: :topics,
      loading: :secondary,
      field: Search::Fields::TOPICS,
      limit: 25,
      facet_resource: :topic_facets,
      facet_index: true,
      facet_search: true,
      missing_value: true
    )

    RELEASED_TO_EARTHWORKS = Config.with_defaults(
      form_field: :released_to_earthworks,
      loading: :secondary,
      date_from_form_field: :released_to_earthworks_date_from,
      date_to_form_field: :released_to_earthworks_date_to,
      field: Search::Fields::RELEASED_TO_EARTHWORKS,
      dynamic_facet: {
        today: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:#{Search::Queries::TODAY}",
        last_7_days: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:#{Search::Queries::LAST_7_DAYS}",
        last_30_days: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:#{Search::Queries::LAST_30_DAYS}",
        year_to_date: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:#{Search::Queries::YEAR_TO_DATE}",
        ever: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:#{Search::Queries::ALL}",
        never: "-#{Search::Fields::RELEASED_TO_EARTHWORKS}:#{Search::Queries::ALL}"
      }
    )

    RELEASED_TO_PURL_SITEMAP = Config.with_defaults(
      form_field: :released_to_purl_sitemap,
      loading: :secondary,
      date_from_form_field: :released_to_purl_sitemap_date_from,
      date_to_form_field: :released_to_purl_sitemap_date_to,
      field: Search::Fields::RELEASED_TO_PURL_SITEMAP,
      dynamic_facet: {
        today: "#{Search::Fields::RELEASED_TO_PURL_SITEMAP}:#{Search::Queries::TODAY}",
        last_7_days: "#{Search::Fields::RELEASED_TO_PURL_SITEMAP}:#{Search::Queries::LAST_7_DAYS}",
        last_30_days: "#{Search::Fields::RELEASED_TO_PURL_SITEMAP}:#{Search::Queries::LAST_30_DAYS}",
        year_to_date: "#{Search::Fields::RELEASED_TO_PURL_SITEMAP}:#{Search::Queries::YEAR_TO_DATE}",
        ever: "#{Search::Fields::RELEASED_TO_PURL_SITEMAP}:#{Search::Queries::ALL}",
        never: "-#{Search::Fields::RELEASED_TO_PURL_SITEMAP}:#{Search::Queries::ALL}"
      }
    )

    RELEASED_TO_SEARCHWORKS = Config.with_defaults(
      form_field: :released_to_searchworks,
      loading: :secondary,
      date_from_form_field: :released_to_searchworks_date_from,
      date_to_form_field: :released_to_searchworks_date_to,
      field: Search::Fields::RELEASED_TO_SEARCHWORKS,
      dynamic_facet: {
        today: "#{Search::Fields::RELEASED_TO_SEARCHWORKS}:#{Search::Queries::TODAY}",
        last_7_days: "#{Search::Fields::RELEASED_TO_SEARCHWORKS}:#{Search::Queries::LAST_7_DAYS}",
        last_30_days: "#{Search::Fields::RELEASED_TO_SEARCHWORKS}:#{Search::Queries::LAST_30_DAYS}",
        year_to_date: "#{Search::Fields::RELEASED_TO_SEARCHWORKS}:#{Search::Queries::YEAR_TO_DATE}",
        ever: "#{Search::Fields::RELEASED_TO_SEARCHWORKS}:#{Search::Queries::ALL}",
        never: "-#{Search::Fields::RELEASED_TO_SEARCHWORKS}:#{Search::Queries::ALL}"
      }
    )

    FORMATS = Config.with_defaults(
      form_field: :formats,
      loading: :secondary,
      field: Search::Fields::FORMATS,
      limit: 100,
      alpha_sort: true,
      missing_value: true
    )

    VERSIONS = Config.with_defaults(
      form_field: :versions,
      loading: :secondary,
      field: Search::Fields::VERSION,
      limit: 100,
      alpha_sort: true
    )

    WORKFLOWS = Config.with_defaults(
      form_field: :wps_workflows,
      loading: :lazy,
      field: Search::Fields::WPS_WORKFLOWS,
      hierarchical_field: Search::Fields::WPS_HIERARCHICAL_WORKFLOWS,
      alpha_sort: false,
      limit: 100,
      facet_resource: :workflow_facets,
      facet_index: true,
      facet_children: true
    )

    # Every facet in source order (Module#constants is unordered), the order filters are queried and serialized.
    ALL = constants.sort_by { |const_name| const_source_location(const_name).last }
                   .map { |const_name| const_get(const_name) }.grep(Config).freeze

    # The facets shown in the search sidebar, in display order.
    SIDEBAR = [
      PROJECTS,
      TAGS,
      TICKETS,
      OBJECT_TYPES,
      CONTENT_TYPES,
      COLLECTIONS,
      ADMIN_POLICIES,
      MIMETYPES,
      FILE_ROLES,
      ACCESS_RIGHTS,
      PROCESSING_STATUSES,
      RELEASED_TO_SEARCHWORKS,
      RELEASED_TO_EARTHWORKS,
      RELEASED_TO_PURL_SITEMAP,
      REGISTERED_DATE,
      LAST_ACCESSIONED_DATE,
      EARLIEST_ACCESSIONED_DATE,
      LAST_PUBLISHED_DATE,
      LAST_OPENED_DATE,
      EMBARGO_RELEASE_DATE,
      WORKFLOWS,
      ERROR_DATE,
      METADATA_SOURCES,
      VERSIONS,
      IDENTIFIERS,
      LANGUAGES,
      LICENSES,
      FORMATS,
      MODS_RESOURCE_TYPES,
      DATES,
      TOPICS,
      GENRES,
      REGIONS
    ].freeze

    # Returned with the item results (Searchers::Item).
    PRIMARY = SIDEBAR.select { |config| config.loading == :primary }.freeze
    # Returned by the secondary facets request (Searchers::SecondaryFacet).
    SECONDARY = SIDEBAR.select { |config| config.loading == :secondary }.freeze
    # Facets with their own endpoints, drawn as routes in config/routes.rb.
    ROUTED = ALL.select(&:facet_resource).freeze
  end
end
