# frozen_string_literal: true

module Contents
  module Validators
    # Validates that the structure of a Content is suitable for a book, whose images are in page Resources.
    class Book < Image
      # @param [Content] content
      # @param [Boolean] dark true if the object is dark
      def initialize(content:, dark:)
        super(content:, dark:, file_set_type: FileSetTypes::PAGE)
      end
    end
  end
end
