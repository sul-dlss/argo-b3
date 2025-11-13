# frozen_string_literal: true

module Search
  # Component for displaying a value-based search facet
  class FacetComponent < ViewComponent::Base
    def initialize(label:, facet_counts:, search_form:, form_field:)
      @label = label
      @facet_counts = facet_counts
      @search_form = search_form
      @form_field = form_field
      super()
    end

    attr_reader :label, :facet_counts, :search_form, :form_field

    def render?
      facet_counts.any?
    end
  end
end
