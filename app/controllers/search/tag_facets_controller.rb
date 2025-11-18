# frozen_string_literal: true

module Search
  # Controller for tag facet
  class TagFacetsController < FacetsApplicationController
    # Render the main facet turbo-frame
    def index
      component = Search::HierarchicalFacetFrameComponent.new(
        facet_counts:,
        search_form:,
        form_field:,
        facet_children_path_helper:,
        facet_search_path_helper:
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
      facet_counts = Searchers::Facet.call(
        search_form:,
        field: OTHER_TAGS,
        limit: 25,
        facet_query: facet_query_param
      )

      component = Search::FacetSearchResultComponent.with_collection(facet_counts)
      render(component, content_type: 'text/html')
    end

    private

    def facet_counts(for_children: false)
      Searchers::HierarchicalFacet.call(search_form:,
                                        field: OTHER_HIERARCHICAL_TAGS,
                                        value: for_children ? parent_value_param : nil,
                                        alpha_sort: true,
                                        limit: 10_000)
    end

    def form_field
      :tags
    end

    def facet_children_path_helper
      method(:children_search_tag_facets_path)
    end

    def facet_search_path_helper
      method(:search_search_tag_facets_path)
    end
  end
end
