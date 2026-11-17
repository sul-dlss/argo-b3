# frozen_string_literal: true

# Whether a file of an object can be downloaded from its staged files, preservation, or stacks.
class FileAvailability
  # @param druid [String] the druid of the object
  # @param cocina_version [Integer] the version of the cocina object
  def initialize(druid:, cocina_version:)
    @druid = druid
    @cocina_version = cocina_version
  end

  # Shelved is checked first, since it needs neither the filesystem nor (for a first version) DSA.
  # @param content_file [ContentFile]
  def available?(content_file)
    content_file.shelve || staged?(content_file) || preserved?(content_file)
  end

  private

  attr_reader :druid, :cocina_version

  def staged?(content_file)
    StagingSupport.find_staged_filepath(druid:, filepath: content_file.filepath).present?
  end

  def preserved?(content_file)
    content_file.preserve && accessioned?
  end

  # A later version can only be opened once the first is accessioned; lazy, since checking a first version
  # requires a DSA request.
  def accessioned?
    return @accessioned if defined?(@accessioned)

    @accessioned = cocina_version > 1 || Sdr::WorkflowService.accessioned?(druid:)
  end
end
