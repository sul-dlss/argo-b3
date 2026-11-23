# frozen_string_literal: true

module Search
  # Component for displaying a value-based search facet
  class FacetComponent < ViewComponent::Base
    # @param facet_counts [Search::FacetCounts] The facet counts to display
    # @param search_form [SearchForm] The current search form
    # @param form_field [Symbol] The facet field name
    # @param exclude_form_field [Symbol, nil] The form field used for excluding values from this facet.
    #   Enables exclude links if provided.
    # @param facet_page_path_helper [Proc, nil] Optional path helper for paging the facet. Enables paging if provided.
    # @param facet_search_path_helper [Proc, nil] Optional path helper for searching the facet. Enables searching
    #   if provided.
    # @param operator_form_field [Symbol, nil] The form field for choosing the facet's operator.
    #   Enables the And/Or toggle if provided.
    # @param checkbox [Boolean] true to display the values as checkboxes
    def initialize(facet_counts:, search_form:, form_field:, exclude_form_field: nil, operator_form_field: nil, # rubocop:disable Metrics/ParameterLists
                   facet_page_path_helper: nil, facet_search_path_helper: nil, checkbox: false)
      @facet_counts = facet_counts
      @search_form = search_form
      @form_field = form_field
      @exclude_form_field = exclude_form_field
      @operator_form_field = operator_form_field
      @facet_page_path_helper = facet_page_path_helper
      @facet_search_path_helper = facet_search_path_helper
      @checkbox = checkbox
      super()
    end

    attr_reader :facet_counts, :search_form, :form_field, :facet_page_path_helper, :facet_search_path_helper,
                :exclude_form_field, :operator_form_field

    def checkbox?
      @checkbox
    end

    def checkbox_description_id
      helpers.facet_id(form_field, suffix: 'checkbox-description')
    end

    def facet_value_component(facet_count)
      args = { count: facet_count.count, search_form:, form_field:, exclude_form_field:, value: facet_count.value,
               label: facet_count.label, data: { turbo_frame: '_top' } }
      return Search::CheckboxFacetValueComponent.new(description_id: checkbox_description_id, **args) if checkbox?

      Search::FacetValueComponent.new(**args)
    end

    def show?
      search_form.selected?(key: form_field) ||
        (exclude_form_field.present? && search_form.selected?(key: exclude_form_field)) ||
        (operator_form_field.present? && search_form.selected?(key: operator_form_field))
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
