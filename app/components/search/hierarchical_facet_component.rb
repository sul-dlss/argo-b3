# frozen_string_literal: true

module Search
  # Component for displaying a hierarchical search facet
  class HierarchicalFacetComponent < ViewComponent::Base
    # @param facet_counts [Search::HierarchicalFacetCounts] The facet counts to display
    # @param search_form [Search::ItemForm] The current search form
    # @param form_field [Symbol] The form field this facet represents
    # @param facet_children_path_helper [Proc] The path helper for fetching facet children
    # @param facet_path_helper [Proc, nil] Optional path helper for paging the facet. Enables paging if provided.
    # @param facet_search_path_helper [Proc, nil] Optional path helper for searching the facet. Enables searching
    #   if provided.
    def initialize(facet_counts:, search_form:, form_field:, facet_children_path_helper:, # rubocop:disable Metrics/ParameterLists
                   facet_path_helper:, facet_search_path_helper: nil)
      @facet_counts = facet_counts
      @search_form = search_form
      @form_field = form_field
      @facet_children_path_helper = facet_children_path_helper
      @facet_path_helper = facet_path_helper
      @facet_search_path_helper = facet_search_path_helper
      super()
    end

    attr_reader :facet_counts, :search_form, :form_field, :facet_children_path_helper, :facet_path_helper,
                :facet_search_path_helper

    def label
      helpers.facet_label(form_field)
    end

    def show?
      search_form.selected?(key: form_field)
    end

    def frame_id
      helpers.facet_id(form_field, suffix: "page#{facet_counts.page}")
    end

    def render?
      facet_counts.any?
    end
  end
end
