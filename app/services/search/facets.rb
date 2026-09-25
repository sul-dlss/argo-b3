# frozen_string_literal: true

module Search
  # Constants for facet configuration
  module Facets # rubocop:disable Metrics/ModuleLength
    def self.find_config_by_form_field(form_field)
      Search::Facets.constants.each do |const_name|
        config = Search::Facets.const_get(const_name)
        return config if config.is_a?(Config) && config.form_field == form_field.to_sym
      end
      nil
    end

    Config = Struct.new('FacetConfig',
                        :form_field,
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
                        # Hash of dynamic facet keys to Solr queries.
                        # This is used for facets like released_to_earthworks.
                        :dynamic_facet,
                        # `composite_facet_field` is a solr field whose values encode "<label>:<druid>"
                        # (see Search::CompositeFacetValue), e.g. "Stanford Theses:druid:bc123df4567".
                        # Set this when a facet needs to filter on an identifier (eg druid) but display and
                        # text-search a human-readable label (eg object title). Since a title alone isn't unique
                        # faceting on the display label directly (like most facets do) is ambiguous for
                        # objects with a shared title.
                        :composite_facet_field) do
      # @return [String] the Solr field to facet/search on
      def facet_field
        composite_facet_field || field
      end
    end

    def Config.with_defaults(**)
      defaults = { alpha_sort: false, limit: 100,
                   facet_index: false, facet_children: false, facet_search: false }
      new(**defaults, **)
    end

    ACCESS_RIGHTS = Config.with_defaults(
      form_field: :access_rights,
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
      field: Search::Fields::APO_DRUID,
      composite_facet_field: Search::Fields::APO_TITLE_DRUID,
      limit: 25,
      facet_resource: :admin_policy_facets,
      facet_index: true,
      facet_search: true
    )

    # Facets and filters on the druid (a title is not a unique identifier), but displays the title
    # via the composite field. Also used for direct links from the Collection show page for items
    # in the collection.
    COLLECTIONS = Config.with_defaults(
      form_field: :collection_druids,
      field: Search::Fields::COLLECTION_DRUIDS,
      composite_facet_field: Search::Fields::COLLECTION_TITLE_DRUIDS,
      limit: 25,
      facet_resource: :collection_facets,
      facet_index: true,
      facet_search: true
    )

    DATES = Config.with_defaults(
      form_field: :dates,
      field: Search::Fields::PUBLICATION_DATE,
      limit: 25,
      facet_resource: :date_facets,
      facet_index: true,
      facet_search: true
    )

    EARLIEST_ACCESSIONED_DATE = Config.with_defaults(
      form_field: :earliest_accessioned_date,
      date_from_form_field: :earliest_accessioned_date_from,
      date_to_form_field: :earliest_accessioned_date_to,
      field: Search::Fields::EARLIEST_ACCESSIONED_DATE,
      dynamic_facet: {
        last_day: "#{Search::Fields::EARLIEST_ACCESSIONED_DATE}:#{Search::Queries::LAST_DAY}",
        last_week: "#{Search::Fields::EARLIEST_ACCESSIONED_DATE}:#{Search::Queries::LAST_WEEK}",
        last_month: "#{Search::Fields::EARLIEST_ACCESSIONED_DATE}:#{Search::Queries::LAST_MONTH}",
        last_year: "#{Search::Fields::EARLIEST_ACCESSIONED_DATE}:#{Search::Queries::LAST_YEAR}",
        all: "#{Search::Fields::EARLIEST_ACCESSIONED_DATE}:#{Search::Queries::ALL}"
      }
    )

    EMBARGO_RELEASE_DATE = Config.with_defaults(
      form_field: :embargo_release_date,
      date_from_form_field: :embargo_release_date_from,
      date_to_form_field: :embargo_release_date_to,
      field: Search::Fields::EMBARGO_RELEASE_DATE,
      dynamic_facet: {
        last_day: "#{Search::Fields::EMBARGO_RELEASE_DATE}:#{Search::Queries::LAST_DAY}",
        last_week: "#{Search::Fields::EMBARGO_RELEASE_DATE}:#{Search::Queries::LAST_WEEK}",
        last_month: "#{Search::Fields::EMBARGO_RELEASE_DATE}:#{Search::Queries::LAST_MONTH}",
        last_year: "#{Search::Fields::EMBARGO_RELEASE_DATE}:#{Search::Queries::LAST_YEAR}",
        all: "#{Search::Fields::EMBARGO_RELEASE_DATE}:#{Search::Queries::ALL}"
      }
    )

    IDENTIFIERS = Config.with_defaults(
      form_field: :identifiers,
      dynamic_facet: {
        has_orcids: "+#{Search::Fields::ORCIDS}:*",
        has_doi: "+#{Search::Fields::DOI}:*",
        has_barcode: "+#{Search::Fields::BARCODES}:*"
      }
    )

    LAST_ACCESSIONED_DATE = Config.with_defaults(
      form_field: :last_accessioned_date,
      date_from_form_field: :last_accessioned_date_from,
      date_to_form_field: :last_accessioned_date_to,
      field: Search::Fields::LAST_ACCESSIONED_DATE,
      dynamic_facet: {
        last_week: "#{Search::Fields::LAST_ACCESSIONED_DATE}:#{Search::Queries::LAST_WEEK}",
        last_month: "#{Search::Fields::LAST_ACCESSIONED_DATE}:#{Search::Queries::LAST_MONTH}",
        all: "#{Search::Fields::LAST_ACCESSIONED_DATE}:#{Search::Queries::ALL}"
      }
    )

    LAST_OPENED_DATE = Config.with_defaults(
      form_field: :last_opened_date,
      date_from_form_field: :last_opened_date_from,
      date_to_form_field: :last_opened_date_to,
      field: Search::Fields::LAST_OPENED_DATE,
      dynamic_facet: {
        more_than_week_ago: "#{Search::Fields::LAST_OPENED_DATE}:#{Search::Queries::MORE_THAN_WEEK_AGO}",
        more_than_month_ago: "#{Search::Fields::LAST_OPENED_DATE}:#{Search::Queries::MORE_THAN_MONTH_AGO}",
        all: "#{Search::Fields::LAST_OPENED_DATE}:#{Search::Queries::ALL}"
      }
    )

    LAST_PUBLISHED_DATE = Config.with_defaults(
      form_field: :last_published_date,
      date_from_form_field: :last_published_date_from,
      date_to_form_field: :last_published_date_to,
      field: Search::Fields::LAST_PUBLISHED_DATE,
      dynamic_facet: {
        last_week: "#{Search::Fields::LAST_PUBLISHED_DATE}:#{Search::Queries::LAST_WEEK}",
        last_month: "#{Search::Fields::LAST_PUBLISHED_DATE}:#{Search::Queries::LAST_MONTH}"
      }
    )

    LICENSES = Config.with_defaults(
      form_field: :licenses,
      field: Search::Fields::LICENSES,
      limit: 50
    )

    MIMETYPES = Config.with_defaults(
      form_field: :mimetypes,
      field: Search::Fields::MIMETYPES,
      limit: 10,
      facet_resource: :mimetype_facets,
      facet_index: true,
      facet_search: true
    )

    CONTENT_TYPES = Config.with_defaults(
      form_field: :content_types,
      field: Search::Fields::CONTENT_TYPES,
      limit: 25
    )

    FILE_ROLES = Config.with_defaults(
      form_field: :file_roles,
      field: Search::Fields::FILE_ROLES,
      limit: 20
    )

    FORMATS = Config.with_defaults(
      form_field: :formats,
      field: Search::Fields::FORMATS,
      limit: 100
    )

    GENRES = Config.with_defaults(
      form_field: :genres,
      field: Search::Fields::GENRES,
      limit: 25,
      facet_resource: :genre_facets,
      facet_index: true,
      facet_search: true
    )

    LANGUAGES = Config.with_defaults(
      form_field: :languages,
      field: Search::Fields::LANGUAGES,
      limit: 25,
      facet_resource: :language_facets,
      facet_index: true,
      facet_search: true
    )

    METADATA_SOURCES = Config.with_defaults(
      form_field: :metadata_sources,
      field: Search::Fields::METADATA_SOURCE,
      limit: 2
    )

    MODS_RESOURCE_TYPES = Config.with_defaults(
      form_field: :mods_resource_types,
      field: Search::Fields::MODS_RESOURCE_TYPES,
      limit: 100
    )

    OBJECT_TYPES = Config.with_defaults(
      form_field: :object_types,
      field: Search::Fields::OBJECT_TYPES
    )

    PROCESSING_STATUSES = Config.with_defaults(
      form_field: :processing_statuses,
      field: Search::Fields::PROCESSING_STATUS,
      limit: 10
    )

    PROJECTS = Config.with_defaults(
      form_field: :projects,
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
      field: Search::Fields::REGIONS,
      limit: 25,
      facet_resource: :region_facets,
      facet_index: true,
      facet_search: true
    )

    REGISTERED_DATE = Config.with_defaults(
      form_field: :registered_date,
      date_from_form_field: :registered_date_from,
      date_to_form_field: :registered_date_to,
      field: Search::Fields::REGISTERED_DATE,
      dynamic_facet: {
        last_week: "#{Search::Fields::REGISTERED_DATE}:#{Search::Queries::LAST_WEEK}",
        last_month: "#{Search::Fields::REGISTERED_DATE}:#{Search::Queries::LAST_MONTH}",
        all: "#{Search::Fields::REGISTERED_DATE}:#{Search::Queries::ALL}"
      }
    )

    RELEASED_TO_EARTHWORKS = Config.with_defaults(
      form_field: :released_to_earthworks,
      dynamic_facet: {
        last_week: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:#{Search::Queries::LAST_WEEK}",
        last_month: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:#{Search::Queries::LAST_MONTH}",
        last_year: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:#{Search::Queries::LAST_YEAR}",
        ever: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:#{Search::Queries::ALL}",
        never: "-#{Search::Fields::RELEASED_TO_EARTHWORKS}:#{Search::Queries::ALL}"
      }
    )

    RELEASED_TO_PURL_SITEMAP = Config.with_defaults(
      form_field: :released_to_purl_sitemap,
      dynamic_facet: {
        last_week: "#{Search::Fields::RELEASED_TO_PURL_SITEMAP}:#{Search::Queries::LAST_WEEK}",
        last_month: "#{Search::Fields::RELEASED_TO_PURL_SITEMAP}:#{Search::Queries::LAST_MONTH}",
        last_year: "#{Search::Fields::RELEASED_TO_PURL_SITEMAP}:#{Search::Queries::LAST_YEAR}",
        ever: "#{Search::Fields::RELEASED_TO_PURL_SITEMAP}:#{Search::Queries::ALL}",
        never: "-#{Search::Fields::RELEASED_TO_PURL_SITEMAP}:#{Search::Queries::ALL}"
      }
    )

    RELEASED_TO_SEARCHWORKS = Config.with_defaults(
      form_field: :released_to_searchworks,
      dynamic_facet: {
        last_week: "#{Search::Fields::RELEASED_TO_SEARCHWORKS}:#{Search::Queries::LAST_WEEK}",
        last_month: "#{Search::Fields::RELEASED_TO_SEARCHWORKS}:#{Search::Queries::LAST_MONTH}",
        last_year: "#{Search::Fields::RELEASED_TO_SEARCHWORKS}:#{Search::Queries::LAST_YEAR}",
        ever: "#{Search::Fields::RELEASED_TO_SEARCHWORKS}:#{Search::Queries::ALL}",
        never: "-#{Search::Fields::RELEASED_TO_SEARCHWORKS}:#{Search::Queries::ALL}"
      }
    )

    TAGS = Config.with_defaults(
      form_field: :tags,
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
      field: Search::Fields::TICKETS,
      alpha_sort: true,
      limit: 25,
      facet_resource: :ticket_facets,
      facet_index: true,
      facet_search: true
    )

    TOPICS = Config.with_defaults(
      form_field: :topics,
      field: Search::Fields::TOPICS,
      limit: 25,
      facet_resource: :topic_facets,
      facet_index: true,
      facet_search: true
    )

    VERSIONS = Config.with_defaults(
      form_field: :versions,
      field: Search::Fields::VERSION,
      limit: 100
    )

    WORKFLOWS = Config.with_defaults(
      form_field: :wps_workflows,
      field: Search::Fields::WPS_WORKFLOWS,
      hierarchical_field: Search::Fields::WPS_HIERARCHICAL_WORKFLOWS,
      alpha_sort: false,
      limit: 100,
      facet_resource: :workflow_facets,
      facet_index: true,
      facet_children: true
    )
  end
end
