# frozen_string_literal: true

module Search
  # Component to display a single current filter applied to a search
  class CurrentFilterComponent < ViewComponent::Base
    def initialize(form_field:, value:, search_form:, facet_labels: {})
      @form_field = form_field
      @value = value
      @search_form = search_form
      @facet_labels = facet_labels
      super()
    end

    attr_reader :form_field, :value, :search_form, :facet_labels

    def label
      return value_label if query?

      "#{field_label} > #{value_label}"
    end

    def remove_path
      url_for(search_form.without({ form_field => value, page: nil }))
    end

    def query?
      form_field == 'query'
    end

    private

    def field_label
      helpers.facet_label(form_field)
    end

    def value_label
      facet_config = Search::Facets.find_config_by_form_field(form_field)
      # Values for dynamic facets may need to be mapped to user-friendly labels.
      return helpers.facet_value_label(value) if facet_config&.dynamic_facet
      # Composite facet values are selected by druid, so resolve the title to display instead.
      return facet_labels.fetch(value, value) if facet_config&.composite_facet_field

      value
    end
  end
end
