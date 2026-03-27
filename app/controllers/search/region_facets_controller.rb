# frozen_string_literal: true

module Search
  # Controller for regions facet
  class RegionFacetsController < FacetsApplicationController
    serves_facet Search::Facets::REGIONS
  end
end
