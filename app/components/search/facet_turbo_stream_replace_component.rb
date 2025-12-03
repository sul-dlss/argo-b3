# frozen_string_literal: true

module Search
  # Component for rendering a turbo stream to replace a search facet
  class FacetTurboStreamReplaceComponent < ViewComponent::Base
    FACET_COMPONENTS = %i[facet checkbox dynamic dynamic_with_date_range].freeze

    # Override the facet component used to render the facet.
    # Default is a Search::FacetComponent.
    renders_one :facet

    # @param facet_config [Search::Facets::Config]
    # @param facet_counts [SearchResults::FacetCounts]
    # @param search_form [Search::ItemForm]
    # @param facet_component [Symbol] type of facet component to render inside turbo stream
    def initialize(facet_config:, facet_counts:, search_form:, facet_component: :facet)
      @facet_config = facet_config
      @facet_counts = facet_counts
      @search_form = search_form
      @facet_component = facet_component
      raise ArgumentError, 'unexpected facet_component' unless FACET_COMPONENTS.include?(facet_component)

      super()
    end

    attr_reader :facet_config, :facet_counts, :search_form, :facet_component

    delegate :form_field, :facet_search_path_helper, :exclude_form_field, :date_from_form_field, :date_to_form_field,
             to: :facet_config

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
