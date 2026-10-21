# frozen_string_literal: true

module Contents
  module Validators
    # A web archive seed may publish at most one JP2 across all of its resources.
    class WebarchiveSeed < Default
      # @return [Contents::Validators::Result]
      def call
        content_file_sets.each.with_index(1) do |content_file_set, index|
          validate_content_file_set(content_file_set:, index:)
        end
        add_warning_or_error('There is more than one published JP2 file.') if published_jp2_count > 1

        result
      end

      private

      def validate_content_file_set(content_file_set:, index:)
        unpublishable_content_files = content_file_set.content_files.select do |content_file|
          content_file.publish && content_file.mime_type != MimeTypes::JP2
        end
        return if unpublishable_content_files.empty?

        name = resource_name_for(content_file_set:, index:)
        add_warning_or_error("#{name} has published files that are not JP2: " \
                             "#{unpublishable_content_files.map(&:filepath).join(', ')}.")
      end

      def published_jp2_count
        content_file_sets.sum do |content_file_set|
          content_file_set.content_files.count do |content_file|
            content_file.publish && content_file.mime_type == MimeTypes::JP2
          end
        end
      end
    end
  end
end
