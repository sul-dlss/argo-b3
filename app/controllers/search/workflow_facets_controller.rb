# frozen_string_literal: true

module Search
  # Controller for workflows facet
  class WorkflowFacetsController < FacetsApplicationController
    # Render the main facet turbo-frame
    def index
      component = Search::HierarchicalFacetFrameComponent.new(
        facet_counts:,
        search_form:,
        form_field:,
        facet_children_path_helper:
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

    private

    def facet_counts(for_children: false)
      Searchers::HierarchicalFacet.call(search_form:,
                                        field: WPS_HIERARCHICAL_WORKFLOWS,
                                        value: for_children ? parent_value_param : nil,
                                        limit: 100)
    end

    def form_field
      :wps_workflows
    end

    def facet_children_path_helper
      method(:children_search_workflow_facets_path)
    end
  end
end
