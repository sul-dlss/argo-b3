# frozen_string_literal: true

module Search
  # Controller for admin policies facet
  class AdminPolicyFacetsController < FacetsApplicationController
    serves_facet Search::Facets::ADMIN_POLICIES
  end
end
