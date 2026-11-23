# frozen_string_literal: true

module Search
  # Component for rendering a turbo stream to update a search facet's placeholder (or earlier content) with the facet
  class FacetTurboStreamUpdateComponent < ViewComponent::Base
    with_collection_parameter :facet_config

    # @param facet_config [Search::Facets::Config]
    # @param results [SearchResults::Items] the search results holding the facet's counts
    # @param search_form [SearchForm]
    def initialize(facet_config:, results:, search_form:)
      @facet_config = facet_config
      @results = results
      @search_form = search_form
      super()
    end

    attr_reader :facet_config, :results, :search_form

    def facet_id
      helpers.facet_id(facet_config.form_field)
    end

    def facet_counts
      results.facet_counts_for(facet_config)
    end
  end
end
