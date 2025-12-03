# frozen_string_literal: true

module Search
  # Controller for genres facet
  class GenreFacetsController < FacetsApplicationController
    include FacetPagingConcern
    include FacetSearchingConcern

    private

    def facet_config
      Search::Facets::GENRES
    end
  end
end
