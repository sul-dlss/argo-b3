# frozen_string_literal: true

module Search
  # Component for displaying a facet in a turbo frame
  class FacetFrameComponent < ViewComponent::Base
    def initialize(facet_counts:, search_form:, form_field:,
                   facet_search_path_helper: nil, facet_path_helper: nil)
      @facet_counts = facet_counts
      @search_form = search_form
      @form_field = form_field
      @facet_search_path_helper = facet_search_path_helper
      @facet_path_helper = facet_path_helper
      super()
    end

    attr_reader :facet_counts, :search_form, :form_field, :facet_search_path_helper,
                :facet_path_helper

    def id
      helpers.facet_id(form_field)
    end
  end
end
