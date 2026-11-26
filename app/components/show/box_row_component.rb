# frozen_string_literal: true

module Show
  # Lays out a row of boxes (e.g., Show::BoxComponent or cards) at a third of the row each, so that boxes on
  # every page, and rows with fewer boxes, share one width and gap. Each child element is a box; below xl they stack.
  # A compact row (e.g., the Multi-Item Deposit summaries) instead lays out small, fixed-width boxes with centered
  # text from the left edge, wrapping as needed; the boxes in a line grow to the tallest one's height (see show.scss).
  class BoxRowComponent < ApplicationComponent
    # @param columns [Integer] boxes per row at xl and up (e.g., 2 for a row nested in a column 2/3 wide)
    # @param compact [Boolean] lay out small, fixed-width boxes instead of a third of the row each
    # @param classes [Array<String>, String] additional classes for the row (e.g., margins)
    # @param options [Hash] additional HTML attributes for the row (e.g., id, role)
    def initialize(columns: 3, compact: false, classes: [], **options)
      @columns = columns
      @compact = compact
      @classes = classes
      @options = options
      super()
    end

    def call
      tag.div(content, class: merge_classes(*layout_classes, *Array(@classes)), **@options)
    end

    private

    def layout_classes
      return ['box-row-compact d-flex flex-wrap column-gap-5 row-gap-3 text-center'] if @compact

      ['row row-cols-1', "row-cols-xl-#{@columns}", 'g-4']
    end
  end
end
