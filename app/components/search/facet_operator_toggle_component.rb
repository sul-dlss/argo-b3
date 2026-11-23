# frozen_string_literal: true

module Search
  # Component for the And/Or toggle that chooses how a checkbox facet's selected values are combined.
  # Choosing an option updates the search, as checking a value does.
  class FacetOperatorToggleComponent < ApplicationComponent
    # @param search_form [SearchForm] the current search
    # @param form_field [Symbol] the facet's form field
    # @param operator_form_field [Symbol] the form field for the facet's operator
    def initialize(search_form:, form_field:, operator_form_field:)
      @search_form = search_form
      @form_field = form_field
      @operator_form_field = operator_form_field
      super()
    end

    attr_reader :search_form, :form_field, :operator_form_field

    def label
      "Combine selected #{helpers.facet_label(form_field).downcase.pluralize} with"
    end

    # @return [Hash] the toggle option arguments, other than form and field_name
    def option_args(operator)
      {
        label: operator.capitalize,
        value: operator,
        checked: operator == selected_operator,
        data: { action: 'change->visit#visit',
                visit_url_param: url_for(search_form.with(operator_form_field => operator, page: nil)) }
      }
    end

    private

    def selected_operator
      search_form.operator_for(Search::Facets.find_config_by_form_field(form_field)).to_s
    end
  end
end
