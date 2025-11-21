# frozen_string_literal: true

module Search
  # Component for displaying a hierarchical facet frame in a turbo frame
  class HierarchicalFacetFrameComponent < ViewComponent::Base
    def initialize(facet_counts:, search_form:, form_field:, facet_children_path_helper:, # rubocop:disable Metrics/ParameterLists
                   facet_search_path_helper: nil, facet_path_helper: nil)
      @facet_counts = facet_counts
      @search_form = search_form
      @form_field = form_field
      @facet_children_path_helper = facet_children_path_helper
      @facet_search_path_helper = facet_search_path_helper
      @facet_path_helper = facet_path_helper
      super()
    end

    attr_reader :facet_counts, :search_form, :form_field, :facet_children_path_helper, :facet_search_path_helper,
                :facet_path_helper

    def id
      helpers.facet_id(form_field)
    end
  end
end
