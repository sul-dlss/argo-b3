# frozen_string_literal: true

module Show
  # Component for the Files and Structure tabs' button that starts a Download files bulk action.
  class DownloadFilesBulkActionComponent < ApplicationComponent
    # @param druid_token [String] signed druid token for the object
    # @param downloadable_files [DownloadableFiles]
    def initialize(druid_token:, downloadable_files:)
      @druid_token = druid_token
      @downloadable_files = downloadable_files
      super()
    end

    attr_reader :druid_token

    # @return [String, nil] why the files cannot be downloaded, if they cannot
    def unavailable_reason
      return t('show.file_sets.no_files_available') if downloadable_files.empty?
      return unless downloadable_files.too_large?

      t('show.file_sets.files_too_large', total_size: helpers.number_to_human_size(downloadable_files.total_size),
                                          max_size: helpers.number_to_human_size(DownloadableFiles.max_size))
    end

    private

    attr_reader :downloadable_files
  end
end
