# frozen_string_literal: true

module Search
  # Component for displaying a value-based search facet with checkboxes
  # This requires that the facet field be marked as tagged in Search::ItemQueryBuilder
  # and marked as excluded in Searchers::Item so that all values are returned.
  class CheckboxFacetComponent < ViewComponent::Base
    def initialize(facet_counts:, search_form:, form_field:)
      @facet_counts = facet_counts
      @search_form = search_form
      @form_field = form_field
      super()
    end

    attr_reader :facet_counts, :search_form, :form_field

    def label
      helpers.facet_label(form_field)
    end

    def render?
      facet_counts.any?
    end
  end
end
