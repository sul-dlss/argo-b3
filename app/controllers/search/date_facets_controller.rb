# frozen_string_literal: true

module Search
  # Controller for dates facet
  class DateFacetsController < FacetsApplicationController
    serves_facet Search::Facets::DATES
  end
end
