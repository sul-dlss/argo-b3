# frozen_string_literal: true

module Contents
  module Validators
    # Warns about files in the structure of a Content that are dark but published.
    class DarkPublishedFiles < Default
      # @return [Contents::Validators::Result]
      def call
        if dark_published_filepaths.any?
          warnings << "Files are dark but published: #{dark_published_filepaths.join(', ')}."
        end

        result
      end

      private

      def dark_published_filepaths
        @dark_published_filepaths ||= content_file_sets.flat_map(&:content_files).filter_map do |content_file|
          next unless content_file.publish
          next unless AccessRightsSupport.dark?(view: content_file.view, download: content_file.download,
                                                location: content_file.location)

          content_file.filepath
        end
      end
    end
  end
end
