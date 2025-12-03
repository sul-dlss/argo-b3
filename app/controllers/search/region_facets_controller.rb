# frozen_string_literal: true

module Search
  # Controller for regions facet
  class RegionFacetsController < FacetsApplicationController
    include FacetPagingConcern
    include FacetSearchingConcern

    private

    def facet_config
      Search::Facets::REGIONS
    end
  end
end
