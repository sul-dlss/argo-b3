# frozen_string_literal: true

module Search
  # Controller for dates facet
  class DateFacetsController < FacetsApplicationController
    include FacetPagingConcern
    include FacetSearchingConcern

    private

    def facet_config
      Search::Facets::DATES
    end
  end
end
