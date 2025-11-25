# frozen_string_literal: true

module Search
  # Component to render a single facet result in search results
  class FacetResultComponent < ViewComponent::Base
    with_collection_parameter :value

    # @param value [String]
    # @param form_field [String] the form field name for building links
    # value_counter is the collection counter provided by with_collection_parameter
    def initialize(value:, value_counter:, form_field:)
      @value = value
      @form_field = form_field
      @index = value_counter + 1
      super()
    end

    attr_reader :value, :form_field, :index

    def id
      "#{form_field}-result-#{value.parameterize}"
    end

    def path
      search_items_path(form_field => [value])
    end
  end
end
