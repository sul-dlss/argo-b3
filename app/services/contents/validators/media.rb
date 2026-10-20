# frozen_string_literal: true

module Contents
  module Validators
    # Validates that the structure of a Content is suitable for media
    class Media < Default
      MEDIA_FILE_SET_TYPES = [FileSetTypes::VIDEO, FileSetTypes::AUDIO].freeze
      MP4_MIME_TYPES = [MimeTypes::MP4_VIDEO, MimeTypes::MP4_AUDIO].freeze
      SOURCE_MIME_TYPES = [MimeTypes::MP3, MimeTypes::MOV, MimeTypes::MKV, MimeTypes::WAV, MimeTypes::X_WAV].freeze
      PUBLISHABLE_RESOURCE_MIME_TYPES = [*MP4_MIME_TYPES, MimeTypes::VTT, MimeTypes::JP2, MimeTypes::PLAIN_TEXT].freeze
      IMAGE_MIME_TYPES = [MimeTypes::JPEG, MimeTypes::TIFF, MimeTypes::PNG, MimeTypes::JP2].freeze

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
        published_content_files = content_file_set.content_files.select(&:publish)
        case content_file_set.file_set_type
        when *MEDIA_FILE_SET_TYPES
          validate_resource(published_content_files:, name:)
        when FileSetTypes::FILE
          # File resources are not validated.
        else
          validate_other(published_content_files:, name:)
        end
      end

      def validate_resource(published_content_files:, name:)
        # NOTE: .many? means > 1
        if published_content_files.many? { |content_file| MP4_MIME_TYPES.include?(content_file.mime_type) }
          add_warning_or_error("#{name} has more than one published MP4/M4A file.")
        end
        unpublishable_content_files = published_content_files.reject do |content_file|
          PUBLISHABLE_RESOURCE_MIME_TYPES.include?(content_file.mime_type)
        end
        return if unpublishable_content_files.empty?

        add_warning_or_error("#{name} has published files that are not MP4/M4A, VTT, JP2, or TXT: " \
                             "#{unpublishable_content_files.map(&:filepath).join(', ')}.")
      end

      def validate_other(published_content_files:, name:)
        return if published_content_files.all? { |content_file| IMAGE_MIME_TYPES.include?(content_file.mime_type) }

        add_warning_or_error("#{name} has published files other than JPEG, TIFF, PNG, or JP2 " \
                             'but is not a video, audio, or file resource.')
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
