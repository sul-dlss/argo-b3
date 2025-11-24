# frozen_string_literal: true

module Search
  # Base controller for facets
  class FacetsApplicationController < SearchApplicationController
    layout false

    # Maximum number of facet values to return for a search.
    SEARCH_LIMIT = 25

    private

    def facet_config
      raise NotImplementedError
    end

    delegate :form_field, :alpha_sort, :limit,
             :facet_path_helper, :facet_children_path_helper, :facet_search_path_helper,
             :field, :hierarchical_field,
             to: :facet_config

    def search_form
      @search_form ||= build_form(form_class: Search::ItemForm)
    end

    def parent_value_param
      params.require(:parent_value)
    end

    def facet_query_param
      params.require(:q)
    end

    def required_page_param
      params.require(:facet_page).to_i
    end

    def page_param
      params[:facet_page]&.to_i
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
