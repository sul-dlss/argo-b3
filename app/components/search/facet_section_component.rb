# frozen_string_literal: true

module Search
  # Component for displaying a facet section (i.e., a wrapper around the facet values)
  class FacetSectionComponent < ApplicationComponent
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
      merge_classes('accordion-collapse collapse', show? ? 'show' : nil)
    end

    def button_classes
      merge_classes('btn accordion-button', show? ? nil : 'collapsed')
    end

    def show?
      @show
    end
  end
end
