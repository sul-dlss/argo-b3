# frozen_string_literal: true

module Search
  # Component to render a single facet result in search results
  class FacetResultComponent < ViewComponent::Base
    with_collection_parameter :value

    # @param value [String]
    # @param form_field [String] the form field name for building links
    def initialize(value:, form_field:)
      @value = value
      @form_field = form_field
      super()
    end

    attr_reader :value, :form_field

    def id
      "#{form_field}-result-#{value.parameterize}"
    end
  end
end
