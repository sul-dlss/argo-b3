# frozen_string_literal: true

module Contents
  module Populators
    # Populates an existing Content with ContentFileSets and ContentFiles for the ContentFileBinaries
    # that are not yet part of its structure.
    # It uses a one FileSet per file strategy.
    class FileSetPerFile < Base
      OBJECT_FILE_SET_TYPE = 'object'

      # @param [Content] content
      # @param [Cocina::Models::DROWithMetadata] cocina_object
      # @param [String] file_set_type type to use for each file set
      def initialize(content:, cocina_object:, file_set_type: OBJECT_FILE_SET_TYPE)
        @file_set_type = file_set_type
        super(content:, cocina_object:)
      end

      attr_reader :file_set_type

      # For this strategy, structuring and appending are the same: Populator clears the structure before
      # structuring, which leaves every binary unassociated.
      def structure
        create_content_file_sets
      end

      def append
        create_content_file_sets
      end

      private

      # New file sets are positioned at the end of the existing file sets by the positioning gem.
      def create_content_file_sets
        unassociated_content_file_binaries.path_order.each do |content_file_binary|
          create_content_file(content_file_binary:)
        end
      end

      def create_content_file(content_file_binary:)
        content_file_set = content.content_file_sets.create!(file_set_type:, label: '')
        content_file_set.content_files.create!(
          content_file_binary:,
          label: '',
          **Contents::FileAttributes.call(mime_type: content_file_binary.mime_type, dark: dark?),
          **file_access_attributes
        )
      end
    end
  end
end
