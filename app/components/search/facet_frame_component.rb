# frozen_string_literal: true

module Search
  # Component for displaying a lazy facet in the turbo frame that replaces its loading frame
  class FacetFrameComponent < ViewComponent::Base
    # @param facet_config [Search::Facets::Config]
    # @param facet_counts [SearchResults::FacetCounts]
    # @param search_form [SearchForm]
    def initialize(facet_config:, facet_counts:, search_form:)
      @facet_config = facet_config
      @facet_counts = facet_counts
      @search_form = search_form
      super()
    end

    attr_reader :facet_config, :facet_counts, :search_form

    def id
      helpers.facet_id(facet_config.form_field)
    end
  end
end
