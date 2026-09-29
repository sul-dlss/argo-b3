# frozen_string_literal: true

module Contents
  module Populators
    # Populates an existing Content with ContentFileSets and ContentFiles for the ContentFileBinaries
    # that are not yet part of its structure.
    # It uses a strategy for creating a book: the files that share a filename (ignoring the extension),
    # e.g., the master, the deliverable, and the OCR for a page, are grouped into a single file set.
    class Book < Image
      PAGE_FILE_SET_TYPE = 'page'

      # @param [Content] content
      # @param [Cocina::Models::DROWithMetadata] cocina_object
      def initialize(content:, cocina_object:)
        super(content:, cocina_object:, image_file_set_type: PAGE_FILE_SET_TYPE)
      end
    end
  end
end
