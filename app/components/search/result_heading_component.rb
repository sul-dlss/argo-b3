# frozen_string_literal: true

module Search
  # Component for rendering a heading for a search result
  class ResultHeadingComponent < ApplicationComponent
    renders_one :link

    def initialize(index:, label: nil, path: nil, classes: [])
      # Provide either a label / link or link slot
      @label = label
      @index = index
      @path = path
      @classes = classes
      super()
    end

    attr_reader :label, :index, :path

    def classes
      merge_classes('d-flex align-items-center', @classes)
    end
  end
end
