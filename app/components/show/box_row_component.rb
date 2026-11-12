# frozen_string_literal: true

module Show
  # Lays out a row of boxes (e.g., Show::BoxComponent or cards) at a third of the row each, so that boxes on
  # every page, and rows with fewer boxes, share one width and gap. Each child element is a box; below xl they stack.
  class BoxRowComponent < ApplicationComponent
    # @param columns [Integer] boxes per row at xl and up (e.g., 2 for a row nested in a column 2/3 wide)
    # @param classes [Array<String>, String] additional classes for the row (e.g., margins)
    # @param options [Hash] additional HTML attributes for the row (e.g., id, role)
    def initialize(columns: 3, classes: [], **options)
      @columns = columns
      @classes = classes
      @options = options
      super()
    end

    def call
      tag.div(content, class: merge_classes('row row-cols-1', "row-cols-xl-#{@columns}", 'g-4', *Array(@classes)),
                       **@options)
    end
  end
end
