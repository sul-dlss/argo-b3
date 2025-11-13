# frozen_string_literal: true

module Search
  # Controller for lazy facets
  class FacetsController < SearchApplicationController
    include Search::Fields

    layout false

    before_action :set_search_form

    def project_tags
      @facet_counts = Searchers::HierarchicalFacet.call(search_form: @search_form, field: PROJECT_HIERARCHICAL_TAGS,
                                                        alpha_sort: true, limit: 10_000)
    end

    def project_tags_children
      component = build_component(
        facet_counts: Searchers::HierarchicalFacet.call(search_form: @search_form, field: PROJECT_HIERARCHICAL_TAGS,
                                                        value: parent_value_param, alpha_sort: true, limit: 10_000),
        path_helper: method(:project_tags_children_search_facets_path),
        form_field: :projects
      )
      render(component, content_type: 'text/html')
    end

    def tags
      @facet_counts = Searchers::HierarchicalFacet.call(search_form: @search_form, field: OTHER_HIERARCHICAL_TAGS,
                                                        alpha_sort: true, limit: 10_000)
    end

    def tags_children
      component = build_component(
        facet_counts: Searchers::HierarchicalFacet.call(search_form: @search_form, field: OTHER_HIERARCHICAL_TAGS,
                                                        value: parent_value_param, alpha_sort: true, limit: 10_000),
        path_helper: method(:tags_children_search_facets_path),
        form_field: :tags
      )
      render(component, content_type: 'text/html')
    end

    def wps_workflows
      @facet_counts = Searchers::HierarchicalFacet.call(search_form: @search_form, field: WPS_HIERARCHICAL_WORKFLOWS,
                                                        limit: 100)
    end

    def wps_workflows_children
      component = build_component(
        facet_counts: Searchers::HierarchicalFacet.call(search_form: @search_form, field: WPS_HIERARCHICAL_WORKFLOWS,
                                                        value: parent_value_param, limit: 100),
        path_helper: method(:wps_workflows_children_search_facets_path),
        form_field: :wps_workflows
      )
      render(component, content_type: 'text/html')
    end

    private

    def set_search_form
      @search_form = build_form(form_class: Search::ItemForm)
    end

    def parent_value_param
      params.require(:parent_value)
    end

    def build_component(facet_counts:, path_helper:, form_field:)
      Search::HierarchicalChildrenComponent.new(
        parent_value: parent_value_param,
        facet_counts:,
        search_form: @search_form,
        path_helper:,
        form_field:
      )
    end
  end
end
