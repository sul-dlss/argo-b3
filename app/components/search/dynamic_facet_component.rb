# frozen_string_literal: true

module Search
  # Component for displaying a dynamic search facet.
  class DynamicFacetComponent < ViewComponent::Base
    def initialize(facet_counts:, search_form:, form_field:)
      @facet_counts = facet_counts
      @search_form = search_form
      @form_field = form_field
      super()
    end

    attr_reader :facet_counts, :search_form, :form_field

    def show?
      search_form.selected?(key: form_field)
    end

    def label
      helpers.facet_label(form_field)
    end

    def render?
      facet_counts.any?
    end
  end
end
