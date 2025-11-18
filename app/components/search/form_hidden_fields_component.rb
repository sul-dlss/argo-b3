# frozen_string_literal: true

module Search
  # Component for generating hidden fields for search form attributes
  class FormHiddenFieldsComponent < ViewComponent::Base
    def initialize(form_builder:, search_form:, form_field: nil, include_base_fields: true)
      @form_builder = form_builder
      @search_form = search_form
      # If form_field is provided, it will be excluded from the hidden fields.
      # Hidden fields will also be created for the fields from Search::Form (e.g., query).
      @form_field = form_field&.to_s
      @include_base_fields = include_base_fields
      super()
    end

    attr_reader :form_builder, :search_form, :form_field

    def query_hidden_field?
      search_form.query.present? && include_base_fields?
    end

    def include_google_books_hidden_field?
      search_form.include_google_books && include_base_fields?
    end

    def include_base_fields?
      @include_base_fields
    end
  end
end
