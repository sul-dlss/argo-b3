# frozen_string_literal: true

module Elements
  # Component for a <div> that acts as a heading for accessibility purposes.
  class DivHeadingComponent < ApplicationComponent
    # @param level [Integer] The heading level (1-6)
    # @param label [String, nil] Optional label for the heading; if nil, uses content.
    def initialize(level:, label: nil, classes: nil, **tag_attrs)
      @level = level
      @label = label
      @classes = classes
      @tag_attrs = tag_attrs
      super()
    end

    attr_reader :level, :label, :tag_attrs

    def classes
      merge_classes(@classes)
    end
  end
end
