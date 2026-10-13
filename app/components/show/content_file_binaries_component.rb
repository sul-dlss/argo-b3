# frozen_string_literal: true

module Show
  # Component for displaying a table of the file binaries of a content.
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
      # content_files are preloaded so that each row can determine whether its binary is preserved.
      @content_file_binaries ||= content_record.content_file_binaries.path_order.includes(:content_files).to_a
    end

    private

    attr_reader :content_record
  end
end
