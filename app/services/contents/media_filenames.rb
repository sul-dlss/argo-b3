# frozen_string_literal: true

module Contents
  # Derives how the files of media are grouped from their filenames. In SMPL mode, filenames follow SMPL's file naming
  # guidelines, in which underscore-separated flags describe a file (e.g., bb010dx6027_t01_pm.wav is the preservation
  # master of track 1); otherwise, files are grouped by basename.
  class MediaFilenames
    ROLE_FLAGS = %w[pm sh sl].freeze
    SCRIPT_FLAG = 'script'
    # Flags that distinguish the files of a recording, rather than distinguishing recordings (e.g., sides or tracks).
    STEM_FLAGS = [*ROLE_FLAGS, 'sp', 'thumb', 'cap', SCRIPT_FLAG].freeze

    # @param [Array<ContentFileBinary>] media_content_file_binaries the audio and video binaries of the content
    def initialize(media_content_file_binaries:)
      @smpl = media_content_file_binaries.any? { |binary| flags_for(binary).intersect?(ROLE_FLAGS) }
    end

    def smpl?
      @smpl
    end

    # @return [String] the stem shared by the files of a recording
    def stem_for(content_file_binary)
      return content_file_binary.basename unless smpl?

      (flags_for(content_file_binary) - STEM_FLAGS).join('_')
    end

    # @return [Boolean] true for an SMPL script, e.g., bb010dx6027_t01_script.pdf
    def script?(content_file_binary)
      smpl? && flags_for(content_file_binary).include?(SCRIPT_FLAG)
    end

    private

    def flags_for(content_file_binary)
      content_file_binary.basename.split('_')
    end
  end
end
