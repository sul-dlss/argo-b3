# frozen_string_literal: true

# Presenter for the download links of an object's files, which download from stage, preservation, or stacks
# (in that order of preference).
class FileDownloadPresenter
  # @param druid [String] the druid of the object
  # @param druid_token [String] signed druid token for the object, used for the download endpoint
  # @param cocina_version [Integer] the version of the cocina object
  def initialize(druid:, druid_token:, cocina_version:)
    @druid = druid
    @druid_token = druid_token
    @cocina_version = cocina_version
  end

  # @param content_file [ContentFile]
  # @return [String, nil] the download link for the file, or nil if it is not available from any source
  def link(content_file:)
    return unless staged?(content_file) || preserved?(content_file) || shelved?(content_file)

    Rails.application.routes.url_helpers.object_file_download_path(druid_token, filepath: content_file.filepath)
  end

  private

  attr_reader :druid, :druid_token, :cocina_version

  def staged?(content_file)
    StagingSupport.find_staged_filepath(druid:, filepath: content_file.filepath).present?
  end

  def preserved?(content_file)
    content_file.preserve && accessioned?
  end

  def shelved?(content_file)
    content_file.shelve && content_file.download != 'none'
  end

  # A later version can only be opened once the first is accessioned; lazy, since checking a first version
  # requires a DSA request.
  def accessioned?
    return @accessioned if defined?(@accessioned)

    @accessioned = cocina_version > 1 || Sdr::WorkflowService.accessioned?(druid:)
  end
end
