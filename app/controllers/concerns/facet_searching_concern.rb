# frozen_string_literal: true

# Concern for controllers handling facet searching.
# The controller must be a subclass of FacetsApplicationController.
module FacetSearchingConcern
  extend ActiveSupport::Concern

  # Maximum number of facet values to return for a search.
  SEARCH_LIMIT = 25

  # Renders the auto-complete search results for the facet
  def search
    facet_counts = Searchers::FacetQuery.call(
      search_form:,
      field:,
      limit: SEARCH_LIMIT,
      facet_query: facet_query_param
    )

    component = Search::FacetSearchResultComponent.with_collection(facet_counts)
    render(component, content_type: 'text/html')
  end
end
