# frozen_string_literal: true

module Contents
  module Validators
    # Validates that none of the files in the structure of a Content have hierarchical filepaths
    # (e.g., folder1/image1.tif), which DSA rejects for all content types except file and geo.
    #
    # Violations are errors even for a dark object, since DSA rejects them regardless of access.
    class HierarchicalFilepaths < Default
      # @return [Contents::Validators::Result]
      def call
        if hierarchical_filepaths.any?
          errors << 'Hierarchical filepaths are only allowed for the file and geo content types: ' \
                    "#{hierarchical_filepaths.join(', ')}."
        end

        result
      end

      private

      def hierarchical_filepaths
        @hierarchical_filepaths ||= content.content_files
                                           .joins(:content_file_binary)
                                           .where('cardinality(content_file_binaries.path_parts) > 0')
                                           .order('content_file_sets.position', :position)
                                           .pluck('content_file_binaries.filepath')
      end
    end
  end
end
