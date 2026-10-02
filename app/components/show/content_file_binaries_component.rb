# frozen_string_literal: true

module Show
  # Component for displaying a table of the file binaries of a content.
  class ContentFileBinariesComponent < ApplicationComponent
    # @param content_record [Content] (named to avoid ViewComponent's reserved content parameter)
    def initialize(content_record:)
      @content_record = content_record
      super()
    end

    def content_file_binaries
      @content_file_binaries ||= content_record.content_file_binaries.path_order.to_a
    end

    private

    attr_reader :content_record
  end
end
