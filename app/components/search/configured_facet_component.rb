# frozen_string_literal: true

module Search
  # Renders a facet with the facet component that its config calls for (checkbox, dynamic, hierarchical, or basic)
  class ConfiguredFacetComponent < ViewComponent::Base
    # @param facet_config [Search::Facets::Config]
    # @param facet_counts [SearchResults::FacetCounts] counts of the type that the facet's searcher returns
    # @param search_form [SearchForm]
    def initialize(facet_config:, facet_counts:, search_form:)
      @facet_config = facet_config
      @facet_counts = facet_counts
      @search_form = search_form
      super()
    end

    def call
      render(facet_component)
    end

    private

    attr_reader :facet_config, :facet_counts, :search_form

    delegate :form_field, :exclude_form_field, :date_from_form_field, :date_to_form_field, to: :facet_config

    def facet_component # rubocop:disable Metrics/AbcSize
      if facet_config.operator == :or
        Search::CheckboxFacetComponent.new(facet_counts:, search_form:, form_field:)
      elsif facet_config.dynamic_facet.present?
        Search::DynamicFacetComponent.new(facet_counts:, search_form:, form_field:,
                                          date_from_form_field:, date_to_form_field:)
      elsif facet_config.hierarchical?
        Search::HierarchicalFacetComponent.new(facet_counts:, search_form:, form_field:,
                                               facet_children_path_helper:,
                                               facet_path_helper: facet_page_path_helper,
                                               facet_search_path_helper:)
      else
        Search::FacetComponent.new(facet_counts:, search_form:, form_field:, exclude_form_field:,
                                   facet_page_path_helper:, facet_search_path_helper:)
      end
    end

    def facet_page_path_helper
      Search::FacetPathResolver.index_path_helper(facet_config:, search_form:)
    end

    def facet_children_path_helper
      Search::FacetPathResolver.children_path_helper(facet_config:, search_form:)
    end

    def facet_search_path_helper
      Search::FacetPathResolver.search_path_helper(facet_config:, search_form:)
    end
  end
end
