# frozen_string_literal: true

module Show
  # Renders the bordered box used for summary and status boxes: atop the object show page (status, released to,
  # tags, etc.), on the bulk action show page, and in the Multi-Item Deposit discovery summary.
  # The box takes its border and background colors from the surrounding object-type-* class (see show.scss).
  class BoxComponent < ApplicationComponent
    # Rendered beside the heading (e.g., an edit button).
    renders_one :heading_action

    # @param heading_level [Symbol] the heading's level, so that the box fits the page's heading outline
    # @param classes [Array<String>, String] additional classes for the box (e.g., text-danger to color its text)
    def initialize(heading:, heading_level: :h2, classes: [])
      @heading = heading
      @heading_level = heading_level
      @classes = classes
      super()
    end

    attr_reader :heading, :heading_level

    def classes
      merge_classes('border object-type-border object-type-bg-light', *Array(@classes))
    end
  end
end
