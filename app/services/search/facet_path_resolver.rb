# frozen_string_literal: true

module Search
  # Resolves the path helpers for a facet's endpoints.
  #
  # Facet endpoints are mounted under each search view's route (see the :search_endpoints routing
  # concern), so the same facet has a different path helper per view, e.g. search_tag_facets_path
  # and workflow_grid_tag_facets_path. Rather than hardcoding helper names, they are built from the
  # facet's resource and the search form's route scope. This is what allows a facet to be rendered
  # in any view without the facet components knowing which view they are in.
  #
  # Each method returns a proc that takes path helper args, or nil if the facet has no such
  # endpoint. Callers treat nil as "this capability is not available for this facet".
  class FacetPathResolver
    class << self
      # Path helper for the facet's index endpoint. Enables lazy loading and paging.
      def index_path_helper(facet_config:, search_form:)
        return unless facet_config.facet_index

        path_helper(facet_config:, search_form:)
      end

      # Path helper for the facet's children endpoint. Only for hierarchical facets.
      def children_path_helper(facet_config:, search_form:)
        return unless facet_config.facet_children

        path_helper(facet_config:, search_form:, prefix: 'children')
      end

      # Path helper for the facet's search endpoint. Enables facet search.
      def search_path_helper(facet_config:, search_form:)
        return unless facet_config.facet_search

        path_helper(facet_config:, search_form:, prefix: 'search')
      end

      private

      def path_helper(facet_config:, search_form:, prefix: nil)
        name = path_helper_name(facet_resource: facet_config.facet_resource,
                                route_scope: search_form.route_scope,
                                prefix:)
        ->(*args) { Rails.application.routes.url_helpers.public_send(name, *args) }
      end

      def path_helper_name(facet_resource:, route_scope:, prefix: nil)
        [prefix, route_scope, facet_resource, 'path'].compact.join('_').to_sym
      end
    end
  end
end
