# frozen_string_literal: true

module Search
  # Controller for genres facet
  class GenreFacetsController < FacetsApplicationController
    serves_facet Search::Facets::GENRES
  end
end
