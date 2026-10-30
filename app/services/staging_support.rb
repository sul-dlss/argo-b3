# frozen_string_literal: true

# Methods for staging support, such as constructing file paths.
class StagingSupport
  # @return [Array<String>] the staging locations, in the order searched
  def self.locations
    [Settings.staging_location, Settings.assembly_location]
  end

  def self.staging_filepath(druid:, filepath:, staging_location: Settings.staging_location)
    File.join(staging_content_path(druid:, staging_location:), filepath)
  end

  def self.staging_content_path(druid:, staging_location: Settings.staging_location)
    druid_tree_folder = DruidTools::Druid.new(druid, staging_location).path
    File.join(druid_tree_folder, 'content')
  end

  # Creates the staging content directory for the druid, unless some staging location already has the druid's folder.
  def self.ensure_staging_folder(druid:)
    return if locations.any? { |staging_location| File.directory?(DruidTools::Druid.new(druid, staging_location).path) }

    FileUtils.mkdir_p(staging_content_path(druid:))
  end

  # Deletes the staging content directory for the druid in every staging location.
  def self.delete_staged_files(druid:)
    locations.each { |staging_location| FileUtils.rm_rf(staging_content_path(druid:, staging_location:)) }
  end

  # @return [Boolean] true if the staging content directory for the druid in any staging location contains files
  #   (including in subdirectories)
  def self.staged_files?(druid:)
    staged_location(druid:).present?
  end

  # @return [String, nil] the first staging location with staged files for the druid
  def self.staged_location(druid:)
    locations.find do |staging_location|
      content_path = staging_content_path(druid:, staging_location:)
      Dir.glob('**/*', base: content_path).any? { |path| File.file?(File.join(content_path, path)) }
    end
  end
end
