# frozen_string_literal: true

module Search
  # Controller for languages facet
  class LanguageFacetsController < FacetsApplicationController
    include FacetPagingConcern
    include FacetSearchingConcern

    private

    def facet_config
      Search::Facets::LANGUAGES
    end
  end
end
