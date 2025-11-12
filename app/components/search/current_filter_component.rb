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
      form_field.humanize
    end

    def title
      "Remove filter #{label}: #{value}"
    end

    def remove_path
      search_items_path(search_form.without_attributes({ form_field => value, page: nil }))
    end
  end
end
