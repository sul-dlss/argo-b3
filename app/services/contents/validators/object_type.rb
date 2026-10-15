# frozen_string_literal: true

module Contents
  module Validators
    # Validates that the structure of a Content is suitable for a content type whose published files
    # are each in their own file Resource (ContentFileSet), e.g., object and webarchive-binary.
    #
    # Violations of the rules for a Resource are errors, except for a dark object, for
    # which they are only warnings since none of its files are expected to be published.
    class ObjectType < Default
      # @return [Contents::Validators::Result]
      def call
        content_file_sets.each.with_index(1) do |content_file_set, index|
          validate_content_file_set(content_file_set:, index:)
        end
        warnings << 'There are no file resources.' unless any_file_resource?

        result
      end

      private

      def validate_content_file_set(content_file_set:, index:)
        name = resource_name_for(content_file_set:, index:)
        published_content_files = content_file_set.content_files.select(&:publish)

        if published_content_files.any? && !file?(content_file_set)
          add_warning_or_error("#{name} has published files but is not a file resource.")
        end
        add_warning_or_error("#{name} has more than one published file.") if published_content_files.many?
      end

      def any_file_resource?
        content_file_sets.any? { |content_file_set| file?(content_file_set) }
      end

      def file?(content_file_set)
        content_file_set.file_set_type == FileSetTypes::FILE
      end
    end
  end
end
