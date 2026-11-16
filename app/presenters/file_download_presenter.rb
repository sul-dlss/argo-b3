# frozen_string_literal: true

# Presenter for the download links of an object's files, which download from stage, preservation, or stacks
# (in that order of preference).
class FileDownloadPresenter
  # @param druid_token [String] signed druid token for the object, used for the download endpoint
  # @param file_availability [FileAvailability]
  def initialize(druid_token:, file_availability:)
    @druid_token = druid_token
    @file_availability = file_availability
  end

  # @param content_file [ContentFile]
  # @return [String, nil] the download link for the file, or nil if it is not available from any source
  def link(content_file:)
    return unless file_availability.available?(content_file)

    Rails.application.routes.url_helpers.object_file_download_path(druid_token, filepath: content_file.filepath)
  end

  private

  attr_reader :druid_token, :file_availability
end
