# frozen_string_literal: true

module Contents
  module Populators
    # Populates an existing Content with ContentFileSets and ContentFiles for the ContentFileBinaries
    # that are not yet part of its structure.
    # It uses a one FileSet per file strategy, where each FileSet is a file. Agreements are always dark, so every
    # file is dark and preserved but not published or shelved, regardless of its mime type.
    class Agreement < FileSetPerFile
      # @param [Content] content
      # @param [Cocina::Models::DROWithMetadata] cocina_object
      def initialize(content:, cocina_object:)
        super(content:, cocina_object:, file_set_type: FileSetTypes::FILE)
      end
    end
  end
end
