# frozen_string_literal: true

module Search
  # Controller for mimetypes facet
  class MimetypeFacetsController < FacetsApplicationController
    # Render the paging turbo-frame
    def index
      component = Search::FacetComponent.new(
        facet_counts:,
        search_form:,
        form_field:,
        facet_page_path_helper: facet_path_helper
      )
      render(component, content_type: 'text/html')
    end

    # Renders the auto-complete search results for the facet
    def search
      facet_counts = Searchers::FacetQuery.call(
        search_form:,
        field: Search::Fields::MIMETYPES,
        limit:,
        facet_query: facet_query_param
      )

      component = Search::FacetSearchResultComponent.with_collection(facet_counts)
      render(component, content_type: 'text/html')
    end

    private

    def facet_config
      Search::Facets::MIMETYPES
    end

    def facet_counts
      Searchers::Facet.call(search_form:,
                            field: Search::Fields::MIMETYPES,
                            limit:,
                            page: required_page_param)
    end
  end
end
