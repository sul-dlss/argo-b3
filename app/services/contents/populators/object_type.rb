# frozen_string_literal: true

module Contents
  module Populators
    # Populates an existing Content with ContentFileSets and ContentFiles for the ContentFileBinaries
    # that are not yet part of its structure.
    # It uses a one FileSet per file strategy, where each FileSet is a file (rather than an object).
    # Confusion warning: You get the "object" type when the user has selected the "file" content type.
    class ObjectType < FileSetPerFile
      # @param [Content] content
      # @param [Cocina::Models::DROWithMetadata] cocina_object
      def initialize(content:, cocina_object:)
        super(content:, cocina_object:, file_set_type: FileSetTypes::FILE)
      end
    end
  end
end
