# frozen_string_literal: true

module Show
  # Component for displaying a row for a file binary of a content.
  # Rows for deposited files can be clicked to show / hide the technical metadata,
  # which is lazily loaded when first shown.
  class ContentFileBinaryRowComponent < ApplicationComponent
    # @param content_file_binary [ContentFileBinary] with content_files preloaded
    # @param druid_token [String] signed druid token for the object, used for loading technical metadata
    def initialize(content_file_binary:, druid_token:)
      @content_file_binary = content_file_binary
      @druid_token = druid_token
      super()
    end

    attr_reader :content_file_binary, :druid_token

    # Technical metadata is only available for files that have been accessioned and preserved.
    # Preserve is a property of the file, so it is determined by the first file that references the binary.
    def technical_metadata?
      content_file_binary.file_location_deposited? && content_file_binary.content_files.first&.preserve
    end

    def technical_metadata_id
      "content-file-binary-#{content_file_binary.id}-technical-metadata"
    end

    def technical_metadata_frame_id
      "#{technical_metadata_id}-frame"
    end

    # Chevron indicating whether the technical metadata is shown, styled like a Bootstrap accordion button.
    def toggle_indicator
      return unless technical_metadata?

      tag.span(class: 'toggle-row-indicator')
    end

    def toggle_row_options
      return {} unless technical_metadata?

      {
        data: { bs_toggle: 'collapse', bs_target: "##{technical_metadata_id}" },
        aria: { expanded: false, controls: technical_metadata_id },
        class: 'toggle-row collapsed'
      }
    end
  end
end
