# frozen_string_literal: true

module Search
  # Component for rendering a turbo stream to replace a search facet
  class FacetTurboStreamReplaceComponent < ViewComponent::Base
    # Override the facet component used to render the facet.
    # Default is a Search::FacetComponent.
    renders_one :facet

    # @param facet_config [Search::Facets::Config]
    # @param facet_counts [SearchResults::FacetCounts]
    # @param search_form [Search::ItemForm]
    def initialize(facet_config:, facet_counts:, search_form:)
      @facet_config = facet_config
      @facet_counts = facet_counts
      @search_form = search_form
      super()
    end

    attr_reader :facet_config, :facet_counts, :search_form

    delegate :form_field, :facet_search_path_helper, to: :facet_config

    def facet_id
      helpers.facet_id(form_field)
    end

    def facet_page_path_helper
      facet_config.facet_path_helper
    end

    def facet_search_path
      facet_search_path_helper.call(search_form.with_attributes(page: nil))
    end

    def facet_search?
      facet_search_path_helper.present?
    end
  end
end
