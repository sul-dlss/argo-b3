# frozen_string_literal: true

module Search
  # Component for displaying a section of search facets, as placeholders that are replaced when each facet loads
  class FacetsSectionComponent < ViewComponent::Base
    def initialize(search_form:)
      @search_form = search_form
      super()
    end

    attr_reader :search_form

    # A lazy facet loads its own frame; the others are replaced by turbo streams from a search request.
    def loading_facet_component(facet_config)
      return Search::LoadingFacetFrameComponent.new(search_form:, facet_config:) if facet_config.lazy?

      Search::LoadingFacetDivComponent.new(facet_config:)
    end
  end
end
