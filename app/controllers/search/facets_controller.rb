# frozen_string_literal: true

module Search
  # Serves the endpoints of every facet in Search::Facets::ROUTED; the route's facet_form_field default picks the facet.
  class FacetsController < SearchApplicationController
    layout false

    SEARCH_LIMIT = 25

    # Renders a lazy facet's frame, or a page of a facet
    def index
      component_class = facet_config.lazy? && page_param.nil? ? FacetFrameComponent : ConfiguredFacetComponent
      render(component_class.new(facet_config:, facet_counts: index_facet_counts, search_form:),
             content_type: 'text/html')
    end

    # Renders the lazy-loaded children of a hierarchical facet value
    def children
      facet_counts = Searchers::HierarchicalFacet.call(search_form:, facet_config:, value: parent_value_param,
                                                       limit: -1, user_scope: current_user_scope)
      component = Search::HierarchicalChildrenComponent.new(
        parent_value: parent_value_param,
        facet_counts:,
        search_form:,
        path_helper: Search::FacetPathResolver.children_path_helper(facet_config:, search_form:),
        form_field: facet_config.form_field
      )
      render(component, content_type: 'text/html')
    end

    def search
      facet_counts = Searchers::FacetQuery.call(
        search_form:,
        facet_config:,
        limit: SEARCH_LIMIT,
        facet_query: facet_query_param,
        user_scope: current_user_scope
      )
      render(Search::FacetSearchResultComponent.with_collection(facet_counts), content_type: 'text/html')
    end

    private

    attr_reader :search_form

    def facet_config
      @facet_config ||= Search::Facets.find_config_by_form_field(params.require(:facet_form_field))
    end

    def index_facet_counts
      searcher = facet_config.hierarchical? ? Searchers::HierarchicalFacet : Searchers::Facet
      searcher.call(search_form:, facet_config:, page: page_param, user_scope: current_user_scope)
    end

    def parent_value_param
      params.require(:parent_value)
    end

    def facet_query_param
      params.require(:q)
    end

    def page_param
      params[:facet_page]&.to_i
    end
  end
end
