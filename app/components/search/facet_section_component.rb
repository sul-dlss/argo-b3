# frozen_string_literal: true

module Search
  # Component for displaying a facet section (i.e., a wrapper around the facet values)
  class FacetSectionComponent < ViewComponent::Base
    def initialize(label:)
      @label = label
      super()
    end

    attr_reader :label
  end
end
