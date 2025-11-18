# frozen_string_literal: true

module Search
  # Base controller for facets
  class FacetsApplicationController < SearchApplicationController
    layout false

    private

    def search_form
      @search_form ||= build_form(form_class: Search::ItemForm)
    end

    def parent_value_param
      params.require(:parent_value)
    end

    def facet_query_param
      params.require(:q)
    end

    def build_children_component(facet_counts:, path_helper:, form_field:)
      Search::HierarchicalChildrenComponent.new(
        parent_value: parent_value_param,
        facet_counts:,
        search_form:,
        path_helper:,
        form_field:
      )
    end
  end
end
