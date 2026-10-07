# frozen_string_literal: true

module Show
  # Component for displaying a table of the file binaries of a content.
  # Rows for deposited files can be clicked to show / hide the technical metadata,
  # which is lazily loaded when first shown.
  class ContentFileBinariesComponent < ApplicationComponent
    # @param content_record [Content] (named to avoid ViewComponent's reserved content parameter)
    # @param druid_token [String] signed druid token for the object, used for loading technical metadata
    def initialize(content_record:, druid_token:)
      @content_record = content_record
      @druid_token = druid_token
      super()
    end

    attr_reader :druid_token

    def content_file_binaries
      # content_files are preloaded to determine whether each binary is preserved.
      @content_file_binaries ||= content_record.content_file_binaries.path_order.includes(:content_files).to_a
    end

    # Technical metadata is only available for files that have been accessioned and preserved.
    # Preserve is a property of the file, so it is determined by the first file that references the binary.
    def technical_metadata?(content_file_binary)
      content_file_binary.file_location_deposited? && content_file_binary.content_files.first&.preserve
    end

    def technical_metadata_id(content_file_binary)
      "content-file-binary-#{content_file_binary.id}-technical-metadata"
    end

    def technical_metadata_frame_id(content_file_binary)
      "#{technical_metadata_id(content_file_binary)}-frame"
    end

    # Chevron indicating whether the technical metadata is shown, styled like a Bootstrap accordion button.
    def toggle_indicator(content_file_binary)
      return unless technical_metadata?(content_file_binary)

      tag.span(class: 'toggle-row-indicator')
    end

    def toggle_row_options(content_file_binary)
      return {} unless technical_metadata?(content_file_binary)

      {
        data: { bs_toggle: 'collapse', bs_target: "##{technical_metadata_id(content_file_binary)}" },
        aria: { expanded: false, controls: technical_metadata_id(content_file_binary) },
        class: 'toggle-row collapsed'
      }
    end

    private

    attr_reader :content_record
  end
end
