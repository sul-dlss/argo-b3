# frozen_string_literal: true

module Contents
  module Validators
    # Rules for a Resource (ContentFileSet) shared by validators: a Resource may publish any files,
    # as long as it has exactly one published primary file (e.g., a JP2) or a source file from which
    # one can be derived.
    module ResourceRules
      IMAGE_MIME_TYPES = [MimeTypes::TIFF, MimeTypes::PNG, MimeTypes::JPEG].freeze

      private

      # A Resource with published files has exactly one published primary file, or a source file instead.
      # @param [ContentFileSet] content_file_set
      # @param [String] name the name of the Resource for messages
      # @param [Array<String>] mime_types the mime types of the primary file
      # @param [String] description the primary file for messages, e.g., JP2
      # @param [Array<String>] source_mime_types the mime types of files from which the primary file can be derived
      # @param [String] source_description the source files for messages, e.g., TIFF, PNG, or JPEG
      def validate_one_published(content_file_set:, name:, mime_types:, description:, # rubocop:disable Metrics/ParameterLists
                                 source_mime_types: [], source_description: nil)
        content_files = content_file_set.content_files
        published_count = content_files.count do |content_file|
          content_file.publish && mime_types.include?(content_file.mime_type)
        end

        if published_count > 1
          add_warning_or_error("#{name} has more than one published #{description} file.")
        elsif published_count.zero? && missing_source?(content_files:, source_mime_types:)
          source_message = source_description ? " or #{source_description} file" : ''
          add_warning_or_error("#{name} has published files but no published #{description} file#{source_message}.")
        end
      end

      # @param [Array<ContentFile>] content_files
      # @param [Array<String>] source_mime_types the mime types of files from which the primary file can be derived
      # @return [Boolean] true if there are published files but none from which the primary file can be derived
      def missing_source?(content_files:, source_mime_types:)
        content_files.any?(&:publish) &&
          content_files.none? { |content_file| source_mime_types.include?(content_file.mime_type) }
      end

      # An image Resource has one published JP2 (or a TIFF, PNG, or JPEG) and at most one TIFF, PNG, or JPEG.
      # @param [ContentFileSet] content_file_set
      # @param [String] name the name of the Resource for messages
      def validate_image_resource(content_file_set:, name:)
        validate_one_published(content_file_set:, name:, mime_types: [MimeTypes::JP2], description: 'JP2',
                               source_mime_types: IMAGE_MIME_TYPES, source_description: 'TIFF, PNG, or JPEG')
        # A resource may have at most one TIFF, PNG, or JPEG (published or not).
        return unless content_file_set.content_files.many? { |content_file| image?(content_file) }

        add_warning_or_error("#{name} has more than one TIFF, PNG, or JPEG file.")
      end

      # A document Resource has one published PDF.
      # @param [ContentFileSet] content_file_set
      # @param [String] name the name of the Resource for messages
      def validate_document_resource(content_file_set:, name:)
        validate_one_published(content_file_set:, name:, mime_types: [MimeTypes::PDF], description: 'PDF')
      end

      # @param [ContentFile] content_file
      # @return [Boolean] true if the file is a JP2
      def jp2?(content_file)
        content_file.mime_type == MimeTypes::JP2
      end

      # @param [ContentFile] content_file
      # @return [Boolean] true if the file is a TIFF, PNG, or JPEG
      def image?(content_file)
        IMAGE_MIME_TYPES.include?(content_file.mime_type)
      end
    end
  end
end
