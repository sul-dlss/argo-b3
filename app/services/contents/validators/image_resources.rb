# frozen_string_literal: true

module Contents
  module Validators
    # Validates that the structure of a Content is suitable for a content type whose images are in
    # Resources (ContentFileSets) of a single file set type, e.g., page resources for a book.
    #
    # Violations of the rules for a Resource are errors, except for a dark object, for
    # which they are only warnings since none of its files are expected to be published.
    class ImageResources < Default
      IMAGE_MIME_TYPES = [MimeTypes::TIFF, MimeTypes::PNG, MimeTypes::JPEG].freeze
      # JP2, XML (ALTO), TXT, and HTML (hOCR)
      PUBLISHABLE_RESOURCE_MIME_TYPES = [
        MimeTypes::JP2, MimeTypes::XML, MimeTypes::TEXT_XML, MimeTypes::PLAIN_TEXT, MimeTypes::HTML, MimeTypes::XHTML
      ].freeze

      # @param [Content] content
      # @param [Boolean] dark true if the object is dark
      # @param [String] resource_file_set_type the file set type of the Resources holding the images, e.g., page
      def initialize(content:, dark:, resource_file_set_type:)
        super(content:, dark:)
        @resource_file_set_type = resource_file_set_type
      end

      # @return [Contents::Validators::Result]
      def call
        content_file_sets.each.with_index(1) do |content_file_set, index|
          validate_content_file_set(content_file_set:, index:)
        end
        unless any_resource_with_image?
          warnings << "No #{resource_file_set_type} resource has a published JP2 or a TIFF, PNG, or JPEG file."
        end

        result
      end

      private

      attr_reader :resource_file_set_type

      def content_file_sets
        @content_file_sets ||= content.content_file_sets.includes(content_files: :content_file_binary).to_a
      end

      def add_warning_or_error(message)
        (dark? ? warnings : errors) << message
      end

      def validate_content_file_set(content_file_set:, index:)
        name = resource_name_for(content_file_set:, index:)
        case content_file_set.file_set_type
        when resource_file_set_type
          validate_resource(content_file_set:, name:)
        when FileSetTypes::OBJECT
          # Object resources are not validated.
        else
          validate_other(content_file_set:, name:)
        end
      end

      def validate_resource(content_file_set:, name:)
        content_files = content_file_set.content_files
        published_content_files = content_files.select(&:publish)

        validate_multiple_jp2(published_content_files:, name:)
        validate_multiple_image(content_files:, name:)
        validate_unpublishable(published_content_files:, name:)
      end

      # A resource may have at most one published JP2.
      def validate_multiple_jp2(published_content_files:, name:)
        return unless published_content_files.many? { |content_file| jp2?(content_file) }

        add_warning_or_error("#{name} has more than one published JP2 file.")
      end

      # A resource may have at most one TIFF, PNG, or JPEG (published or not).
      def validate_multiple_image(content_files:, name:)
        return unless content_files.many? { |content_file| image?(content_file) }

        add_warning_or_error("#{name} has more than one TIFF, PNG, or JPEG file.")
      end

      # A resource may publish only its image (JP2) and OCR (XML, TXT, or HTML) files.
      def validate_unpublishable(published_content_files:, name:)
        unpublishable_content_files = published_content_files.reject do |content_file|
          PUBLISHABLE_RESOURCE_MIME_TYPES.include?(content_file.mime_type)
        end
        return if unpublishable_content_files.empty?

        add_warning_or_error("#{name} has published files that are not JP2, XML, TXT, or HTML: " \
                             "#{unpublishable_content_files.map(&:filepath).join(', ')}.")
      end

      # Only image-holding and object resources may have published files.
      def validate_other(content_file_set:, name:)
        return if content_file_set.content_files.none?(&:publish)

        add_warning_or_error("#{name} has published files but is not #{article} #{resource_file_set_type} " \
                             'or object resource.')
      end

      def any_resource_with_image?
        content_file_sets.any? do |content_file_set|
          content_file_set.file_set_type == resource_file_set_type &&
            content_file_set.content_files.any? do |content_file|
              (content_file.publish && jp2?(content_file)) || image?(content_file)
            end
        end
      end

      def article
        resource_file_set_type.match?(/\A[aeiou]/) ? 'an' : 'a'
      end

      def jp2?(content_file)
        content_file.mime_type == MimeTypes::JP2
      end

      def image?(content_file)
        IMAGE_MIME_TYPES.include?(content_file.mime_type)
      end

      # @param [Integer] index the 1-based position of the Resource among all of the Resources
      # @return [String] the name of the Resource for messages, e.g., Resource 3 (Page 3)
      def resource_name_for(content_file_set:, index:)
        return "Resource #{index}" if content_file_set.label.blank?

        "Resource #{index} (#{content_file_set.label})"
      end
    end
  end
end
