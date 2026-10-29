# frozen_string_literal: true

module Contents
  module Validators
    # Validates that the structure of a Content is suitable for media, whose media are in video or audio Resources
    # (ContentFileSets). A video or audio Resource may publish any files alongside exactly one published MP4/M4A
    # (see ResourceRules); image and document Resources follow the same rules as for an image or document.
    #
    # Violations of the rules for a Resource are errors, except for a dark object, for
    # which they are only warnings since none of its files are expected to be published.
    class Media < Default
      include ResourceRules

      MEDIA_FILE_SET_TYPES = [FileSetTypes::VIDEO, FileSetTypes::AUDIO].freeze
      MP4_MIME_TYPES = [MimeTypes::MP4_VIDEO, MimeTypes::MP4_AUDIO].freeze
      SOURCE_MIME_TYPES = [MimeTypes::MP3, MimeTypes::MOV, MimeTypes::MKV, MimeTypes::WAV, MimeTypes::X_WAV].freeze

      # @return [Contents::Validators::Result]
      def call
        content_file_sets.each.with_index(1) do |content_file_set, index|
          validate_content_file_set(content_file_set:, index:)
        end
        unless any_resource_with_media?
          warnings << 'No video or audio resource has exactly one MP4 (video) or M4A (audio) file, ' \
                      'or an MP3, MOV, MKV, or WAV file.'
        end

        result
      end

      private

      def validate_content_file_set(content_file_set:, index:)
        name = resource_name_for(content_file_set:, index:)
        case content_file_set.file_set_type
        when *MEDIA_FILE_SET_TYPES
          validate_one_published(content_file_set:, name:, mime_types: MP4_MIME_TYPES, description: 'MP4/M4A',
                                 source_mime_types: SOURCE_MIME_TYPES, source_description: 'MP3, MOV, MKV, or WAV')
        when FileSetTypes::IMAGE
          # An image Resource has one published JP2 (or a TIFF, PNG, or JPEG) and at most one TIFF, PNG, or JPEG.
          validate_image_resource(content_file_set:, name:)
        when FileSetTypes::DOCUMENT
          # A document Resource has one published PDF.
          validate_document_resource(content_file_set:, name:)
        when FileSetTypes::FILE
          # File resources are not validated.
        else
          validate_other(content_file_set:, name:)
        end
      end

      # Only video, audio, image, document, and file resources may have published files.
      def validate_other(content_file_set:, name:)
        return if content_file_set.content_files.none?(&:publish)

        add_warning_or_error("#{name} has published files but is not a video, audio, image, document, " \
                             'or file resource.')
      end

      def any_resource_with_media?
        content_file_sets.any? do |content_file_set|
          next false unless MEDIA_FILE_SET_TYPES.include?(content_file_set.file_set_type)

          resource_with_media?(content_file_set)
        end
      end

      def resource_with_media?(content_file_set)
        content_files = content_file_set.content_files
        media_mime_type = content_file_set.file_set_type == FileSetTypes::VIDEO ? MimeTypes::MP4_VIDEO : MimeTypes::MP4_AUDIO
        content_files.one? { |content_file| content_file.mime_type == media_mime_type } ||
          content_files.any? { |content_file| SOURCE_MIME_TYPES.include?(content_file.mime_type) }
      end
    end
  end
end
