# frozen_string_literal: true

module Search
  # Component for displaying a single facet value in a search facet
  class FacetValueComponent < ViewComponent::Base
    def initialize(count:, search_form:, form_field:, value:, selected:, label: nil, **link_args) # rubocop:disable Metrics/ParameterLists
      @label = label || value
      @count = count
      @search_form = search_form
      @form_field = form_field
      @value = value
      @selected = selected
      @link_args = link_args
      super()
    end

    attr_reader :label, :count, :search_form, :form_field, :value, :link_args

    def selected?
      @selected
    end
  end
end
