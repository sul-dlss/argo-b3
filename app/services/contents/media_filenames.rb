# frozen_string_literal: true

module Contents
  # Derives how the files of media are grouped from their filenames. In SMPL mode, filenames follow SMPL's file naming
  # guidelines, in which underscore-separated flags describe a file (e.g., bb010dx6027_t01_pm.wav is the preservation
  # master of track 1); otherwise, files are grouped by basename.
  class MediaFilenames
    ROLE_FLAGS = %w[pm sh sl].freeze
    SCRIPT_FLAG = 'script'
    CAPTION_FLAG = 'cap'
    # A BCP-47 tag before the caption flag gives the caption's language, e.g., bb010dx6027_t01_es_cap.vtt.
    LANGUAGE_TAG_PATTERN = /\A[a-z]{2,3}(-[a-z0-9]{2,8})*\z/i
    # Flags that distinguish the files of a recording, rather than distinguishing recordings (e.g., sides or tracks).
    STEM_FLAGS = [*ROLE_FLAGS, 'sp', 'thumb', CAPTION_FLAG, SCRIPT_FLAG].freeze

    # @param [Array<ContentFileBinary>] media_content_file_binaries the audio and video binaries of the content
    def initialize(media_content_file_binaries:)
      @media_content_file_binaries = media_content_file_binaries
      @smpl = media_content_file_binaries.any? { |binary| flags_for(binary).intersect?(ROLE_FLAGS) }
    end

    def smpl?
      @smpl
    end

    # @return [String] the stem shared by the files of a recording
    def stem_for(content_file_binary)
      return content_file_binary.basename unless smpl?

      flags = flags_for(content_file_binary)
      language_tag_index = language_tag_index_for(content_file_binary)
      flags.delete_at(language_tag_index) if language_tag_index
      (flags - STEM_FLAGS).join('_')
    end

    # @return [String, nil] the language of an SMPL caption, e.g., es for bb010dx6027_t01_es_cap.vtt
    def language_tag_for(content_file_binary)
      language_tag_index = language_tag_index_for(content_file_binary)
      flags_for(content_file_binary)[language_tag_index] if language_tag_index
    end

    # @return [Boolean] true for an SMPL script, e.g., bb010dx6027_t01_script.pdf
    def script?(content_file_binary)
      smpl? && flags_for(content_file_binary).include?(SCRIPT_FLAG)
    end

    private

    attr_reader :media_content_file_binaries

    # A recording's own flag (e.g., side ab) is not mistaken for a language when it is part of a recording's stem.
    def language_tag_index_for(content_file_binary)
      return unless smpl?

      flags = flags_for(content_file_binary)
      index = flags.index(CAPTION_FLAG)&.pred
      return unless index&.positive?

      index if language_tag?(flags[index]) && media_stems.exclude?((flags - STEM_FLAGS).join('_'))
    end

    def language_tag?(flag)
      STEM_FLAGS.exclude?(flag) && LANGUAGE_TAG_PATTERN.match?(flag)
    end

    def media_stems
      @media_stems ||= media_content_file_binaries.to_set { |binary| (flags_for(binary) - STEM_FLAGS).join('_') }
    end

    def flags_for(content_file_binary)
      content_file_binary.basename.split('_')
    end
  end
end
