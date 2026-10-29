# frozen_string_literal: true

module Search
  # Component for generating hidden fields for search form attributes
  class FormHiddenFieldsComponent < ViewComponent::Base
    # @param form_builder [ActionView::Helpers::FormBuilder] The form builder for the search form
    # @param search_form [SearchForm] The search form object containing the search parameters
    # @param form_fields [Symbol, Array<Symbol>, nil] The form fields to exclude from hidden fields
    def initialize(form_builder:, search_form:, form_fields: nil)
      @form_builder = form_builder
      @search_form = search_form
      # Hidden fields will also be created for the fields from SearchForm (e.g., query).
      @form_fields = Array(form_fields).map(&:to_s)
      super()
    end

    attr_reader :form_builder, :search_form, :form_fields

    def query_hidden_field?
      search_form.query.present? && form_fields.exclude?('query')
    end
  end
end
