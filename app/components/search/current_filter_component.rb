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

    def title
      "Remove filter #{label}: #{value_label}"
    end

    def remove_path
      search_items_path(search_form.without_attributes({ form_field => value, page: nil }))
    end
  end
end
