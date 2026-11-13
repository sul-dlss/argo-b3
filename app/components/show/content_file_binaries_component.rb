# frozen_string_literal: true

module Show
  # Component for displaying a table of the file binaries of a content, within collapsible folders.
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

    # Staged files are checked when rendering, since they stay staged until accessioning completes.
    def staged?(content_file_binary)
      @staged_filepaths ||= StagingSupport.staged_filepaths(druid: content_record.druid,
                                                            filepaths: content_file_binaries.map(&:filepath))
      @staged_filepaths.include?(content_file_binary.filepath)
    end

    # Keyed by druid (not content) so that expanded folders stay expanded when the object's lock changes.
    def table_id
      "#{content_record.druid.delete_prefix('druid:')}-files"
    end

    private

    attr_reader :content_record
  end
end
