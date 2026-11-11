# frozen_string_literal: true

module Show
  # Component for a file's View button that shows / hides its technical metadata below it, lazily loaded when shown.
  class TechnicalMetadataToggleComponent < ApplicationComponent
    # @param content_file_binary [ContentFileBinary] with content_files preloaded
    # @param druid_token [String] signed druid token for the object, used for loading technical metadata
    # @param staged [Boolean] true if the file is staged, and so not yet deposited
    def initialize(content_file_binary:, druid_token:, staged: false)
      @content_file_binary = content_file_binary
      @druid_token = druid_token
      @staged = staged
      super()
    end

    attr_reader :content_file_binary, :druid_token

    # Technical metadata is only available for files that have been deposited (accessioned) and preserved.
    # A Content built from the cocina object marks every file deposited, including those staged in the open version.
    # Preserve is a property of the file, so it is determined by the first file that references the binary.
    def render?
      !@staged && content_file_binary.file_location_deposited? && content_file_binary.content_files.first&.preserve
    end

    def technical_metadata_id
      "content-file-binary-#{content_file_binary.id}-technical-metadata"
    end

    def technical_metadata_frame_id
      "#{technical_metadata_id}-frame"
    end
  end
end
