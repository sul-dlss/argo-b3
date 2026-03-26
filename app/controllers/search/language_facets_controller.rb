# frozen_string_literal: true

module Search
  # Controller for languages facet
  class LanguageFacetsController < FacetsApplicationController
    serves_facet Search::Facets::LANGUAGES
  end
end
