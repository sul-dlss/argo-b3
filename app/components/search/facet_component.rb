# frozen_string_literal: true

module Search
  # Component for displaying a value-based search facet
  class FacetComponent < ViewComponent::Base
    # @param facet_counts [Search::FacetCounts] The facet counts to display
    # @param search_form [Search::ItemForm] The current search form
    # @param form_field [Symbol] The facet field name
    # @param exclude_form_field [Symbol, nil] The form field used for excluding values from this facet.
    #   Enables exclude links if provided.
    # @param facet_page_path_helper [Proc, nil] Optional path helper for paging the facet. Enables paging if provided.
    # @param facet_search_path_helper [Proc, nil] Optional path helper for searching the facet. Enables searching
    #   if provided.
    def initialize(facet_counts:, search_form:, form_field:, exclude_form_field: nil, facet_page_path_helper: nil, # rubocop:disable Metrics/ParameterLists
                   facet_search_path_helper: nil)
      @facet_counts = facet_counts
      @search_form = search_form
      @form_field = form_field
      @exclude_form_field = exclude_form_field
      @facet_page_path_helper = facet_page_path_helper
      @facet_search_path_helper = facet_search_path_helper
      super()
    end

    attr_reader :facet_counts, :search_form, :form_field, :facet_page_path_helper, :facet_search_path_helper,
                :exclude_form_field

    def show?
      search_form.selected?(key: form_field)
    end

    def label
      helpers.facet_label(form_field)
    end

    def frame_id
      helpers.facet_id(form_field, suffix: "page#{facet_counts.page}")
    end

    def render?
      facet_counts.any?
    end
  end
end
