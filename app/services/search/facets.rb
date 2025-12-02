# frozen_string_literal: true

module Search
  # Constants for facet configuration
  module Facets # rubocop:disable Metrics/ModuleLength
    def self.to_path_helper(path_name)
      ->(*args) { Rails.application.routes.url_helpers.public_send(path_name, *args) }
    end

    def self.find_config_by_form_field(form_field)
      Search::Facets.constants.each do |const_name|
        config = Search::Facets.const_get(const_name)
        return config if config.is_a?(Config) && config.form_field == form_field.to_sym
      end
      nil
    end

    Config = Struct.new('Config',
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
                        # Path helper for the index endpoint for the facet.
                        # This is used for a lazy facet and/or a pageable facet.
                        # If is included and the number of facet values exceeds the limit, paging will be enabled.
                        :facet_path_helper,
                        # Path helper for the children endpoint for a hierarchical facet.
                        :facet_children_path_helper,
                        # Path helper for the search endpoint for a facet that supports searching.
                        # If provided, search will be enabled for the facet.
                        :facet_search_path_helper,
                        # Exclude means that there is a tagged filter that should be ignored when calculating the facet.
                        # See FacetBuilder.
                        # This is used, for example, for a checkbox facet like object types.
                        # Note that this is unrelated to the exclude_form_field above.
                        :exclude,
                        # Hash of dynamic facet keys to Solr queries.
                        # This is used for facets like released_to_earthworks.
                        :dynamic_facet,
                        keyword_init: true)

    def Config.with_defaults(**)
      defaults = { alpha_sort: false, limit: 100, exclude: false }
      new(**defaults, **)
    end

    ACCESS_RIGHTS = Config.with_defaults(
      form_field: :access_rights,
      field: Search::Fields::ACCESS_RIGHTS,
      exclude_form_field: :access_rights_exclude,
      limit: 50,
      alpha_sort: true
    )

    ADMIN_POLICIES = Config.with_defaults(
      form_field: :admin_policy_titles,
      field: Search::Fields::APO_TITLE,
      limit: 25,
      facet_path_helper: to_path_helper(:search_admin_policy_facets_path),
      facet_search_path_helper: to_path_helper(:search_search_admin_policy_facets_path)
    )

    COLLECTIONS = Config.with_defaults(
      form_field: :collection_titles,
      field: Search::Fields::COLLECTION_TITLES,
      limit: 25,
      facet_path_helper: to_path_helper(:search_collection_facets_path),
      facet_search_path_helper: to_path_helper(:search_search_collection_facets_path)
    )

    DATES = Config.with_defaults(
      form_field: :dates,
      field: Search::Fields::PUBLICATION_DATE,
      limit: 25,
      facet_path_helper: to_path_helper(:search_date_facets_path),
      facet_search_path_helper: to_path_helper(:search_search_date_facets_path)
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
      facet_path_helper: to_path_helper(:search_mimetype_facets_path),
      facet_search_path_helper: to_path_helper(:search_search_mimetype_facets_path)
    )

    CONTENT_TYPES = Config.with_defaults(
      form_field: :content_types,
      field: Search::Fields::CONTENT_TYPES,
      limit: 25,
      exclude: true
    )

    FILE_ROLES = Config.with_defaults(
      form_field: :file_roles,
      field: Search::Fields::FILE_ROLES,
      limit: 20,
      exclude: true
    )

    GENRES = Config.with_defaults(
      form_field: :genres,
      field: Search::Fields::GENRES,
      limit: 25,
      facet_path_helper: to_path_helper(:search_genre_facets_path),
      facet_search_path_helper: to_path_helper(:search_search_genre_facets_path)
    )

    LANGUAGES = Config.with_defaults(
      form_field: :languages,
      field: Search::Fields::LANGUAGES,
      limit: 25,
      facet_path_helper: to_path_helper(:search_language_facets_path),
      facet_search_path_helper: to_path_helper(:search_search_language_facets_path)
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
      field: Search::Fields::OBJECT_TYPES,
      exclude: true
    )

    PROCESSING_STATUSES = Config.with_defaults(
      form_field: :processing_statuses,
      field: Search::Fields::PROCESSING_STATUS,
      limit: 10,
      exclude: true
    )

    PROJECTS = Config.with_defaults(
      form_field: :projects,
      field: Search::Fields::PROJECTS_EXPLODED,
      hierarchical_field: Search::Fields::PROJECTS_HIERARCHICAL,
      alpha_sort: true,
      limit: 25,
      facet_path_helper: to_path_helper(:search_project_facets_path),
      facet_children_path_helper: to_path_helper(:children_search_project_facets_path),
      facet_search_path_helper: to_path_helper(:search_search_project_facets_path)
    )

    REGIONS = Config.with_defaults(
      form_field: :regions,
      field: Search::Fields::REGIONS,
      limit: 25,
      facet_path_helper: to_path_helper(:search_region_facets_path),
      facet_search_path_helper: to_path_helper(:search_search_region_facets_path)
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

    SW_RESOURCE_TYPES = Config.with_defaults(
      form_field: :sw_resource_types,
      field: Search::Fields::SW_RESOURCE_TYPES,
      limit: 100
    )

    TAGS = Config.with_defaults(
      form_field: :tags,
      field: Search::Fields::OTHER_TAGS,
      hierarchical_field: Search::Fields::OTHER_HIERARCHICAL_TAGS,
      alpha_sort: true,
      limit: 25,
      facet_path_helper: to_path_helper(:search_tag_facets_path),
      facet_children_path_helper: to_path_helper(:children_search_tag_facets_path),
      facet_search_path_helper: to_path_helper(:search_search_tag_facets_path)
    )

    TICKETS = Config.with_defaults(
      form_field: :tickets,
      field: Search::Fields::TICKETS,
      alpha_sort: true,
      limit: 25,
      facet_path_helper: to_path_helper(:search_ticket_facets_path),
      facet_search_path_helper: to_path_helper(:search_search_ticket_facets_path)
    )

    TOPICS = Config.with_defaults(
      form_field: :topics,
      field: Search::Fields::TOPICS,
      limit: 25,
      facet_path_helper: to_path_helper(:search_topic_facets_path),
      facet_search_path_helper: to_path_helper(:search_search_topic_facets_path)
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
      facet_path_helper: to_path_helper(:search_workflow_facets_path),
      facet_children_path_helper: to_path_helper(:children_search_workflow_facets_path)
    )
  end
end
