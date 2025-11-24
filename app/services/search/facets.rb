# frozen_string_literal: true

module Search
  # Constants for facet configuration
  module Facets
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

    MIMETYPES = Config.with_defaults(
      form_field: :mimetypes,
      field: Search::Fields::MIMETYPES,
      limit: 10,
      facet_path_helper: to_path_helper(:search_mimetype_facets_path),
      facet_search_path_helper: to_path_helper(:search_search_mimetype_facets_path)
    )

    PROJECTS = Config.with_defaults(
      form_field: :projects,
      field: Search::Fields::PROJECT_TAGS,
      hierarchical_field: Search::Fields::PROJECT_HIERARCHICAL_TAGS,
      alpha_sort: true,
      limit: 25,
      facet_path_helper: to_path_helper(:search_project_facets_path),
      facet_children_path_helper: to_path_helper(:children_search_project_facets_path),
      facet_search_path_helper: to_path_helper(:search_search_project_facets_path)
    )

    OBJECT_TYPES = Config.with_defaults(
      form_field: :object_types,
      field: Search::Fields::OBJECT_TYPE,
      exclude: true
    )

    RELEASED_TO_EARTHWORKS = Config.with_defaults(
      form_field: :released_to_earthworks,
      dynamic_facet: {
        last_week: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:[NOW-7DAY/DAY TO NOW]",
        last_month: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:[NOW-1MONTH/DAY TO NOW]",
        last_year: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:[NOW-1YEAR/DAY TO NOW]",
        ever: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:[* TO *]",
        never: "-#{Search::Fields::RELEASED_TO_EARTHWORKS}:[* TO *]"
      }
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
