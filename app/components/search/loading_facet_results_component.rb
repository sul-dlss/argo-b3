# frozen_string_literal: true

module Search
  # Component for displaying a placeholder while facet results are loading
  class LoadingFacetResultsComponent < ApplicationComponent
    def initialize(label:)
      @label = label
      super()
    end

    attr_reader :label

    def number_of_placeholders
      5
    end
  end
end
