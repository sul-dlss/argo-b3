# frozen_string_literal: true

module Search
  # Component for a single checkbox input within a checkbox facet
  class CheckboxFacetInputComponent < ViewComponent::Base
    with_collection_parameter :facet_count

    def initialize(facet_count:, search_form:, form_field:, form_builder:)
      @facet_count = facet_count
      @search_form = search_form
      @form_field = form_field
      @form_builder = form_builder
      super()
    end

    attr_reader :facet_count, :search_form, :form_field, :form_builder

    delegate :value, :count, to: :facet_count

    def checked?
      search_form.selected?(key: form_field, value: facet_count.value)
    end
  end
end
