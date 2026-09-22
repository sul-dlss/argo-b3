# frozen_string_literal: true

module Contents
  module Populators
    # Populates an existing Content with ContentFileSets and ContentFiles for the ContentFileBinaries
    # that are not yet part of its structure.
    # It uses a one FileSet per file strategy.
    class FileSetPerFile < Base
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
        unassociated_content_file_binaries.order(:id).each do |content_file_binary|
          create_content_file(content_file_binary:)
        end
      end

      def create_content_file(content_file_binary:)
        content_file_set = content.content_file_sets.create!(file_set_type: 'object', label: '')
        content_file_set.content_files.create!(content_file_binary:, **file_attributes)
      end

      def file_attributes
        {
          label: '',
          preserve: true,
          publish: true,
          shelve: true,
          **file_access_attributes
        }
      end
    end
  end
end
