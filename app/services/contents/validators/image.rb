# frozen_string_literal: true

module Contents
  module Validators
    # Validates that the structure of a Content is suitable for an image (or map), whose images are in
    # image Resources (ContentFileSets). Subclasses may validate Resources of another file set type.
    # An image Resource may publish any files alongside exactly one published JP2 (see ResourceRules).
    #
    # Violations of the rules for a Resource are errors, except for a dark object, for
    # which they are only warnings since none of its files are expected to be published.
    class Image < Default
      include ResourceRules

      # @param [Content] content
      # @param [Boolean] dark true if the object is dark
      # @param [String] file_set_type the file set type of the Resources holding the images
      def initialize(content:, dark:, file_set_type: FileSetTypes::IMAGE)
        super(content:, dark:)
        @file_set_type = file_set_type
      end

      # @return [Contents::Validators::Result]
      def call
        content_file_sets.each.with_index(1) do |content_file_set, index|
          validate_content_file_set(content_file_set:, index:)
        end
        unless any_resource_with_image?
          warnings << "No #{file_set_type} resource has a published JP2 or a TIFF, PNG, or JPEG file."
        end

        result
      end

      private

      attr_reader :file_set_type

      def validate_content_file_set(content_file_set:, index:)
        name = resource_name_for(content_file_set:, index:)
        case content_file_set.file_set_type
        when file_set_type
          # An image Resource has one published JP2 (or a TIFF, PNG, or JPEG) and at most one TIFF, PNG, or JPEG.
          validate_image_resource(content_file_set:, name:)
        when FileSetTypes::OBJECT
          # Object resources are not validated.
        else
          validate_other(content_file_set:, name:)
        end
      end

      # Only image-holding and object resources may have published files.
      def validate_other(content_file_set:, name:)
        return if content_file_set.content_files.none?(&:publish)

        add_warning_or_error("#{name} has published files but is not #{article} #{file_set_type} " \
                             'or object resource.')
      end

      def any_resource_with_image?
        content_file_sets.any? do |content_file_set|
          content_file_set.file_set_type == file_set_type &&
            content_file_set.content_files.any? do |content_file|
              (content_file.publish && jp2?(content_file)) || image?(content_file)
            end
        end
      end

      def article
        file_set_type.match?(/\A[aeiou]/) ? 'an' : 'a'
      end
    end
  end
end
