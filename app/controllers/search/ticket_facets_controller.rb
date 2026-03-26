# frozen_string_literal: true

module Search
  # Controller for ticket facet
  class TicketFacetsController < FacetsApplicationController
    serves_facet Search::Facets::TICKETS

    # Render the main facet turbo-frame (when no page param) or a paged facet (when page param present)
    def index
      component = if page_param.present?
                    Search::FacetComponent.new(
                      facet_counts:,
                      search_form:,
                      form_field:,
                      facet_page_path_helper: facet_path_helper
                    )
                  else
                    Search::FacetFrameComponent.new(
                      facet_counts:,
                      search_form:,
                      form_field:,
                      facet_path_helper:, # This enables paging.
                      facet_search_path_helper: # This enables the facet search functionality.
                    )
                  end
      render(component, content_type: 'text/html')
    end

    private

    def facet_counts
      Searchers::Facet.call(search_form:,
                            facet_config:,
                            page: page_param)
    end
  end
end
