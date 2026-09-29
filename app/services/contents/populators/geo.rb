# frozen_string_literal: true

module Contents
  module Populators
    # Populates an existing Content with ContentFileSets and ContentFiles for the ContentFileBinaries
    # that are not yet part of its structure.
    # It uses a strategy for creating a geo object: all of the files are placed in a single object file set.
    class Geo < Base
      OBJECT_FILE_SET_TYPE = 'object'

      # For this strategy, structuring and appending are the same: Base clears the structure before
      # structuring, which leaves every binary unassociated and no file set to append to.
      def structure
        create_content_files
      end

      def append
        create_content_files
      end

      private

      def create_content_files
        unassociated_content_file_binaries.path_order.each do |content_file_binary|
          content_file_set.content_files.create!(
            content_file_binary:,
            label: content_file_binary.filepath,
            **Contents::FileAttributes.call(mime_type: content_file_binary.mime_type, dark: dark?),
            **file_access_attributes
          )
        end
      end

      # When appending, new files join the first existing file set so that the object remains a single
      # file set (unless the structure has been edited by hand).
      def content_file_set
        @content_file_set ||= content.content_file_sets.first ||
                              content.content_file_sets.create!(file_set_type: OBJECT_FILE_SET_TYPE, label: '')
      end
    end
  end
end
