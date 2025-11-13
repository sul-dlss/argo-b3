# frozen_string_literal: true

module Search
  # Component for displaying hierarchical facet children in a search facet
  class HierarchicalChildrenComponent < ViewComponent::Base
    def initialize(parent_value:, facet_counts:, search_form:, path_helper:, form_field:)
      @parent_value = parent_value
      @facet_counts = facet_counts
      @search_form = search_form
      @path_helper = path_helper
      @form_field = form_field
      super()
    end

    attr_reader :parent_value, :facet_counts, :search_form, :path_helper, :form_field

    def id
      "children-of-#{parent_value.parameterize}"
    end
  end
end
