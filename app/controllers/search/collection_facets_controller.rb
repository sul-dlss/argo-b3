# frozen_string_literal: true

module Search
  # Controller for collections facet
  class CollectionFacetsController < FacetsApplicationController
    include FacetPagingConcern
    include FacetSearchingConcern

    private

    def facet_config
      Search::Facets::COLLECTIONS
    end
  end
end
