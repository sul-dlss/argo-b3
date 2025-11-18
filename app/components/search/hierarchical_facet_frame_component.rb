# frozen_string_literal: true

module Search
  # Component for displaying a hierarchical facet frame in a turbo frame
  class HierarchicalFacetFrameComponent < ViewComponent::Base
    def initialize(facet_counts:, search_form:, form_field:, facet_children_path_helper:,
                   facet_search_path_helper: nil)
      @facet_counts = facet_counts
      @search_form = search_form
      @form_field = form_field
      @facet_children_path_helper = facet_children_path_helper
      @facet_search_path_helper = facet_search_path_helper
      super()
    end

    attr_reader :facet_counts, :search_form, :form_field, :facet_children_path_helper, :facet_search_path_helper

    def facet_search_path
      facet_search_path_helper.call(search_form.with_attributes(page: nil))
    end

    def facet_search?
      facet_search_path_helper.present?
    end

    def id
      helpers.facet_id(form_field)
    end
  end
end
