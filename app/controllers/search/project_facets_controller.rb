# frozen_string_literal: true

module Search
  # Controller for project facet
  class ProjectFacetsController < FacetsApplicationController
    def index
      component = Search::HierarchicalFacetFrameComponent.new(
        facet_counts:,
        search_form:,
        form_field:,
        facet_path_helper:, # This enables paging.
        facet_children_path_helper:,
        facet_search_path_helper: # This enables the facet search functionality.
      )
      render(component, content_type: 'text/html')
    end

    # Renders the lazy-loaded children of a hierarchical facet value
    def children
      component = build_children_component(
        facet_counts: facet_counts(for_children: true),
        path_helper: facet_children_path_helper,
        form_field:
      )
      render(component, content_type: 'text/html')
    end

    # Renders the auto-complete search results for the facet
    def search
      facet_counts = Searchers::FacetQuery.call(
        search_form:,
        field:,
        limit:,
        facet_query: facet_query_param
      )

      component = Search::FacetSearchResultComponent.with_collection(facet_counts)
      render(component, content_type: 'text/html')
    end

    private

    def facet_config
      Search::Facets::PROJECTS
    end

    def facet_counts(for_children: false)
      Searchers::HierarchicalFacet.call(search_form:,
                                        field: hierarchical_field,
                                        value: for_children ? parent_value_param : nil,
                                        alpha_sort:,
                                        limit: for_children ? -1 : SEARCH_LIMIT,
                                        page: page_param)
    end
  end
end
