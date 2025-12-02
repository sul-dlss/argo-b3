# frozen_string_literal: true

module Search
  # Controller for admin policies facet
  class AdminPolicyFacetsController < FacetsApplicationController
    include FacetPagingConcern
    include FacetSearchingConcern

    private

    def facet_config
      Search::Facets::ADMIN_POLICIES
    end
  end
end
