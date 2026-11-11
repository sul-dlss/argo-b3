# frozen_string_literal: true

module Contents
  module Populators
    # Populates an existing Content with ContentFileSets and ContentFiles for the ContentFileBinaries
    # that are not yet part of its structure.
    # It uses a strategy for creating media: audio and video files that share a stem (see MediaFilenames), along with
    # their captions, are grouped into a video or audio file set, followed by image file sets and then a file file set
    # per other file. See MediaFileAttributes for which files are published.
    class Media < Base
      VIDEO_MIME_TYPES = [MimeTypes::MP4_VIDEO, MimeTypes::MOV, MimeTypes::MKV].freeze
      AUDIO_MIME_TYPES = [MimeTypes::MP4_AUDIO, MimeTypes::MP3, MimeTypes::WAV, MimeTypes::X_WAV].freeze
      MEDIA_MIME_TYPES = (VIDEO_MIME_TYPES + AUDIO_MIME_TYPES).freeze
      BASIC_IMAGE_MIME_TYPES = [MimeTypes::TIFF, MimeTypes::JPEG, MimeTypes::PNG].freeze
      SMPL_IMAGE_MIME_TYPES = [MimeTypes::TIFF].freeze
      TRANSCRIPT_MIME_TYPES = [MimeTypes::PDF, MimeTypes::PLAIN_TEXT].freeze

      MEDIA_LABEL_NAMES = { FileSetTypes::VIDEO => 'Video file', FileSetTypes::AUDIO => 'Audio file' }.freeze
      TRANSCRIPT_LABEL_SUFFIX = ' transcript'

      # DSA rejects hierarchical filepaths for media.
      # @return [Array<Symbol>] the reasons that the content cannot be structured as media.
      def self.disqualifying_reasons(content:, **)
        [].tap do |reasons|
          reasons << :hierarchical_filepaths if content.hierarchical_filepaths?
          reasons << :no_media if content.content_file_binaries.none? { |binary| media?(binary) }
        end
      end

      def self.media?(content_file_binary)
        MEDIA_MIME_TYPES.include?(content_file_binary.mime_type)
      end

      delegate :media?, to: :class

      # For this strategy, structuring and appending are the same: Base clears the structure before
      # structuring, which leaves every binary unassociated and no file sets to append to.
      def structure
        populate
      end

      # New binaries join an existing file set with the same stem; the existing file set's type, label, and position
      # are left alone. Re-structuring is the way to get a clean re-derivation.
      def append
        populate
      end

      private

      delegate :smpl?, :stem_for, :language_tag_for, to: :media_filenames

      # The video and audio file sets come first, then the image file sets, then the other files in path order.
      def populate
        content_file_binaries = unassociated_content_file_binaries.path_order.to_a
        media_groups = media_groups_for(content_file_binaries)
        remaining_content_file_binaries = content_file_binaries - media_groups.values.flatten
        image_groups = image_groups_for(remaining_content_file_binaries)

        media_groups.each { |stem, binaries| populate_media_content_file_set(stem:, content_file_binaries: binaries) }
        populate_image_content_file_sets(image_groups)
        (remaining_content_file_binaries - image_groups.flat_map(&:last)).each do |content_file_binary|
          create_file_content_file_set(content_file_binary:)
        end
      end

      # Captions (and, in SMPL mode, thumbnails) join the audio or video files, new or existing, with the same stem.
      # @return [Hash<String,Array<ContentFileBinary>>] the binaries for each video or audio file set by stem
      def media_groups_for(content_file_binaries)
        media_stems = content_file_binaries.select { |binary| media?(binary) }.map { stem_for(it) }
        media_stems |= existing_media_content_file_sets.keys
        media_group_binaries = content_file_binaries.select do |binary|
          media?(binary) || (media_companion?(binary) && media_stems.include?(stem_for(binary)))
        end
        media_group_binaries.group_by { stem_for(it) }
      end

      # Images with the same basename are each a file set, and a JP2 joins the first of them (or else an existing one).
      # @return [Array<Array(ContentFileSet, Array<ContentFileBinary>)>] for each image file set, the existing file set
      #   (nil for a new one) and the binaries to add to it, in path order
      def image_groups_for(content_file_binaries)
        content_file_binaries.select { |binary| image?(binary) }.group_by(&:basename).flat_map do |basename, binaries|
          jp2_binaries, source_binaries = binaries.partition { |binary| binary.mime_type == MimeTypes::JP2 }
          next [[existing_image_content_file_sets[basename], jp2_binaries]] if source_binaries.empty?

          [[nil, jp2_binaries + [source_binaries.first]], *source_binaries.drop(1).map { |binary| [nil, [binary]] }]
        end
      end

      def populate_media_content_file_set(stem:, content_file_binaries:)
        content_file_set = existing_media_content_file_sets[stem] ||=
          create_media_content_file_set(content_file_binaries)
        existing_content_files = content_file_set.content_files.to_a
        media_file_attributes = media_file_attributes_for(existing_content_files.map(&:content_file_binary) +
                                                          content_file_binaries)
        content_file_binaries.each do |content_file_binary|
          create_content_file(content_file_set:, content_file_binary:,
                              attributes: media_file_attributes.attributes_for(content_file_binary))
        end
        # Gaining an access copy can change which files are published; otherwise, edits by hand are retained.
        return unless content_file_binaries.any? { |binary| Contents::MediaFileAttributes.access?(binary) }

        media_file_attributes.update!(existing_content_files)
      end

      # @param [Array<ContentFileBinary>] content_file_binaries all of the binaries in the file set
      def media_file_attributes_for(content_file_binaries)
        Contents::MediaFileAttributes.new(content_file_binaries:, smpl: smpl?, dark: dark?)
      end

      def create_media_content_file_set(content_file_binaries)
        file_set_type = if content_file_binaries.any? { |binary| VIDEO_MIME_TYPES.include?(binary.mime_type) }
                          FileSetTypes::VIDEO
                        else
                          FileSetTypes::AUDIO
                        end
        content.content_file_sets.create!(file_set_type:,
                                          label: label_for(file_set_type, name: MEDIA_LABEL_NAMES.fetch(file_set_type)))
      end

      def populate_image_content_file_sets(image_groups)
        image_count = file_set_type_counts[FileSetTypes::IMAGE] + image_groups.count { |content_file_set, _| !content_file_set }
        image_groups.each do |content_file_set, content_file_binaries|
          content_file_set ||= content.content_file_sets.create!(file_set_type: FileSetTypes::IMAGE,
                                                                 label: image_label(image_count:))
          content_file_binaries.each do |content_file_binary|
            create_content_file(content_file_set:, content_file_binary:)
          end
        end
      end

      # In SMPL mode, images are numbered among all of the images, e.g., Image of media (1 of 2). The count includes
      # the images being added, so it may differ from the labels of existing images.
      def image_label(image_count:)
        return label_for(FileSetTypes::IMAGE) unless smpl?

        image_number = file_set_type_counts[FileSetTypes::IMAGE] += 1
        "Image of media (#{image_number} of #{image_count})"
      end

      # In SMPL mode, a script for a recording is a transcript labeled after the recording's file set.
      def create_file_content_file_set(content_file_binary:)
        media_content_file_set = transcript_media_content_file_set_for(content_file_binary)
        label = if media_content_file_set
                  "#{media_content_file_set.label}#{TRANSCRIPT_LABEL_SUFFIX}"
                else
                  label_for(FileSetTypes::FILE)
                end
        content_file_set = content.content_file_sets.create!(file_set_type: FileSetTypes::FILE, label:)
        attributes = Contents::FileAttributes.call(mime_type: content_file_binary.mime_type, dark: dark?)
        attributes = attributes.merge(use: 'transcription') if media_content_file_set
        create_content_file(content_file_set:, content_file_binary:, attributes:)
      end

      def create_content_file(content_file_set:, content_file_binary:,
                              attributes: Contents::FileAttributes.call(mime_type: content_file_binary.mime_type,
                                                                        dark: dark?))
        content_file_set.content_files.create!(content_file_binary:, label: content_file_binary.filepath,
                                               language_tag: language_tag_for(content_file_binary),
                                               **attributes, **file_access_attributes)
      end

      # @return [ContentFileSet, nil] the video or audio file set that a script is the transcript for
      def transcript_media_content_file_set_for(content_file_binary)
        return unless TRANSCRIPT_MIME_TYPES.include?(content_file_binary.mime_type) &&
                      media_filenames.script?(content_file_binary)

        existing_media_content_file_sets[stem_for(content_file_binary)]
      end

      # @return [Boolean] true for a file that joins the video or audio file set with the same stem
      def media_companion?(content_file_binary)
        content_file_binary.mime_type == MimeTypes::VTT || (smpl? && content_file_binary.mime_type == MimeTypes::JP2)
      end

      def image?(content_file_binary)
        image_mime_types = smpl? ? SMPL_IMAGE_MIME_TYPES : BASIC_IMAGE_MIME_TYPES
        content_file_binary.mime_type == MimeTypes::JP2 || image_mime_types.include?(content_file_binary.mime_type)
      end

      # Decided from all of the binaries, so that appending uses the same mode as structuring.
      def media_filenames
        @media_filenames ||= Contents::MediaFilenames.new(
          media_content_file_binaries: content.content_file_binaries.select { |binary| media?(binary) }
        )
      end

      # @return [Hash<String,ContentFileSet>] the video and audio file sets (existing and since created) by the stem of
      #   their audio and video files. When more than one file set matches a stem, the lowest position wins.
      def existing_media_content_file_sets
        @existing_media_content_file_sets ||= content_file_sets_by(file_set_types: MEDIA_LABEL_NAMES.keys) do |binary|
          stem_for(binary) if media?(binary)
        end
      end

      # @return [Hash<String,ContentFileSet>] the existing image file sets by the basename of their images
      def existing_image_content_file_sets
        @existing_image_content_file_sets ||= content_file_sets_by(file_set_types: [FileSetTypes::IMAGE]) do |binary|
          binary.basename if image?(binary)
        end
      end

      # @yieldparam [ContentFileBinary] the binary of a file in the file set
      # @yieldreturn [String, nil] the key for the file set, or nil to skip the file
      def content_file_sets_by(file_set_types:)
        content.content_file_sets.where(file_set_type: file_set_types).includes(content_files: :content_file_binary)
               .each_with_object({}) do |content_file_set, lookup|
          content_file_set.content_files.each do |content_file|
            key = yield(content_file.content_file_binary)
            lookup[key] ||= content_file_set if key
          end
        end
      end

      # Transcripts are labeled after their video or audio file set, so they are not numbered as files.
      def numbered_content_file_sets
        content.content_file_sets.where.not(ContentFileSet.arel_table[:label].matches("%#{TRANSCRIPT_LABEL_SUFFIX}"))
      end
    end
  end
end
