# frozen_string_literal: true

module Elements
  module Tables
    # Component for rendering a table cell.
    class CellComponent < ApplicationComponent
      def initialize(colspan: nil, classes: [])
        @colspan = colspan
        @classes = classes
        super()
      end

      attr_reader :colspan

      def classes
        merge_classes(@classes)
      end
    end
  end
end
