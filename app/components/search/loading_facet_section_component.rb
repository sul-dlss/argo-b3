# frozen_string_literal: true

module Search
  # Component for displaying a facet section that is loading
  class LoadingFacetSectionComponent < ApplicationComponent
    def initialize(label:)
      @label = label
      super()
    end

    attr_reader :label
  end
end
