# frozen_string_literal: true

module Search
  # Controller for collections facet
  class CollectionFacetsController < FacetsApplicationController
    serves_facet Search::Facets::COLLECTIONS
  end
end
