# frozen_string_literal: true

module Search
  # Controller for mimetypes facet
  class MimetypeFacetsController < FacetsApplicationController
    serves_facet Search::Facets::MIMETYPES
  end
end
