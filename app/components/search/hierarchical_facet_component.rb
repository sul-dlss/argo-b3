# frozen_string_literal: true

module Search
  # Component for displaying a hierarchical search facet
  class HierarchicalFacetComponent < ViewComponent::Base
    renders_one :facet_search, ->(**args) { Search::FacetSearchComponent.new(form_field:, search_form:, **args) }

    def initialize(facet_counts:, search_form:, form_field:, path_helper:)
      @facet_counts = facet_counts
      @search_form = search_form
      @form_field = form_field
      @path_helper = path_helper
      super()
    end

    attr_reader :facet_counts, :search_form, :form_field, :path_helper

    def label
      helpers.facet_label(form_field)
    end

    def show?
      search_form.selected?(key: form_field)
    end

    def render?
      facet_counts.present?
    end
  end
end
