# frozen_string_literal: true

module Search
  # Base controller for facets
  class FacetsApplicationController < SearchApplicationController
    layout false

    SEARCH_LIMIT = 25

    def self.serves_facet(config)
      define_method(:facet_config) { config }
    end

    def index
      facet_counts = Searchers::Facet.call(search_form:, facet_config:, page: required_page_param)
      component = Search::FacetComponent.new(
        facet_counts:,
        search_form:,
        form_field:,
        facet_page_path_helper: facet_path_helper
      )
      render(component, content_type: 'text/html')
    end

    def search
      facet_counts = Searchers::FacetQuery.call(
        search_form:,
        field:,
        limit: SEARCH_LIMIT,
        facet_query: facet_query_param
      )
      render(Search::FacetSearchResultComponent.with_collection(facet_counts), content_type: 'text/html')
    end

    private

    def facet_config
      raise NotImplementedError
    end

    delegate :form_field, :alpha_sort, :limit,
             :facet_path_helper, :facet_children_path_helper, :facet_search_path_helper,
             :field, :hierarchical_field,
             to: :facet_config

    attr_reader :search_form

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
