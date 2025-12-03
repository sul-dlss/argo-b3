# frozen_string_literal: true

module Search
  # Controller for topics facet
  class TopicFacetsController < FacetsApplicationController
    include FacetPagingConcern
    include FacetSearchingConcern

    private

    def facet_config
      Search::Facets::TOPICS
    end
  end
end
