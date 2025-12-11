# frozen_string_literal: true

module Search
  # Component for generating hidden fields for search form attributes
  class FormHiddenFieldsComponent < ViewComponent::Base
    # @param form_builder [ActionView::Helpers::FormBuilder] The form builder for the search form
    # @param search_form [SearchForm] The search form object containing the search parameters
    # @param form_field [Symbol, nil] The specific form field to exclude from hidden
    def initialize(form_builder:, search_form:, form_field: nil)
      @form_builder = form_builder
      @search_form = search_form
      # If form_field is provided, it will be excluded from the hidden fields.
      # Hidden fields will also be created for the fields from SearchForm (e.g., query).
      @form_field = form_field&.to_s
      super()
    end

    attr_reader :form_builder, :search_form, :form_field

    def query_hidden_field?
      search_form.query.present? && form_field != 'query'
    end

    def include_google_books_hidden_field?
      search_form.include_google_books && form_field != 'include_google_books'
    end
  end
end
