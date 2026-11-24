# frozen_string_literal: true

module Dashboard
  # Component for a collapsible section of the dashboard, e.g., a table of pinned items.
  class SectionComponent < ApplicationComponent
    # @param pinned [Boolean] whether the section lists pins, which shows a pin icon in the heading
    # @param expanded [Boolean] whether the section is initially expanded
    # @param classes [Array<String>] e.g., the object-type class that colors the pins
    def initialize(id:, label:, pinned: false, expanded: true, classes: [])
      @id = id
      @label = label
      @pinned = pinned
      @expanded = expanded
      @classes = classes
      super()
    end

    attr_reader :id, :label

    def pinned? = @pinned

    def expanded? = @expanded

    def classes
      merge_classes('mb-5', @classes)
    end
  end
end
