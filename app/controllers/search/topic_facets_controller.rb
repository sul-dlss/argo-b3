# frozen_string_literal: true

module Search
  # Controller for topics facet
  class TopicFacetsController < FacetsApplicationController
    serves_facet Search::Facets::TOPICS
  end
end
