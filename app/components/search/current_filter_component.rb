# frozen_string_literal: true

module Search
  # Component to display a single current filter applied to a search
  class CurrentFilterComponent < ViewComponent::Base
    def initialize(form_field:, value:, search_form:)
      @form_field = form_field
      @value = value
      @search_form = search_form
      super()
    end

    attr_reader :form_field, :value, :search_form

    def label
      return value_label if query?
      return field_label if include_google_books?

      "#{field_label} > #{value_label}"
    end

    def remove_path
      search_path(search_form.without_attributes({ form_field => value, page: nil }))
    end

    def query?
      form_field == 'query'
    end

    def include_google_books?
      form_field == 'include_google_books'
    end

    private

    def field_label
      helpers.facet_label(form_field)
    end

    def value_label
      # Values for dynamic facets may need to be mapped to user-friendly labels.
      facet_config = Search::Facets.find_config_by_form_field(form_field)
      if facet_config&.dynamic_facet
        helpers.facet_value_label(value)
      else
        value
      end
    end
  end
end
