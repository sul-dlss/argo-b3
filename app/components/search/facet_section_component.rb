# frozen_string_literal: true

module Search
  # Component for displaying a facet section (i.e., a wrapper around the facet values)
  class FacetSectionComponent < ViewComponent::Base
    def initialize(label:, show: false)
      @label = label
      @show = show
      super()
    end

    attr_reader :label

    def collapse_id
      "#{label.parameterize}-collapse"
    end

    def collapse_classes
      @show ? 'accordion-collapse collapse show' : 'accordion-collapse collapse'
    end
  end
end
