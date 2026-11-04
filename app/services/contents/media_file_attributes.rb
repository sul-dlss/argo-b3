# frozen_string_literal: true

module Contents
  # Determines the preserve / shelve / publish flags and role for the files of a video or audio Resource, which depend
  # on the other files in the Resource.
  class MediaFileAttributes
    ACCESS_MIME_TYPES = [MimeTypes::MP4_VIDEO, MimeTypes::MP4_AUDIO].freeze
    PUBLISHED = { preserve: true, shelve: true, publish: true, use: nil }.freeze

    def self.access?(content_file_binary)
      ACCESS_MIME_TYPES.include?(content_file_binary.mime_type)
    end

    # @param [Array<ContentFileBinary>] content_file_binaries all of the binaries in the Resource
    # @param [Boolean] smpl when true, the access copy is published (see MediaFilenames)
    # @param [Boolean] dark when true, the files are preserved only
    def initialize(content_file_binaries:, smpl:, dark:)
      @content_file_binaries = content_file_binaries
      @smpl = smpl
      @dark = dark
    end

    # @return [Hash] the preserve, shelve, publish, and use attributes for the file
    def attributes_for(content_file_binary)
      attributes = if content_file_binary == published_access_binary
                     PUBLISHED
                   elsif content_file_binary.mime_type == MimeTypes::VTT
                     caption_attributes
                   else
                     Contents::FileAttributes.call(mime_type: content_file_binary.mime_type, dark: false)
                   end
      dark ? attributes.merge(Contents::FileAttributes::DARK) : attributes
    end

    # @param [Array<ContentFile>] content_files the files in the Resource to update with their attributes
    def update!(content_files)
      content_files.each { |content_file| content_file.update!(**attributes_for(content_file.content_file_binary)) }
    end

    private

    attr_reader :content_file_binaries, :smpl, :dark

    # In simple mode, every audio and video file is preserve-only, since SDR is expected to generate the access copy.
    # In SMPL mode, the smallest MP4/M4A is the access copy and any larger ones are masters.
    def published_access_binary
      return unless smpl

      @published_access_binary ||= content_file_binaries.select { |binary| self.class.access?(binary) }.min_by(&:size)
    end

    # In SMPL mode, captions are only published alongside a published access copy.
    def caption_attributes
      published = !smpl || published_access_binary.present?
      (published ? PUBLISHED : Contents::FileAttributes::DEFAULT).merge(use: 'caption')
    end
  end
end
