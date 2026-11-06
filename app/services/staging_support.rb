# frozen_string_literal: true

# Methods for staging support, such as constructing file paths.
class StagingSupport
  # @return [Array<String>] the staging locations, in the order searched
  def self.locations
    [Settings.staging_location, Settings.assembly_location]
  end

  # The assembly of geo objects (gisAssemblyWF) and web archive seeds (wasSeedPreassemblyWF) reads staged files
  # only from the assembly location.
  # @param [Cocina::Models::DRO, Cocina::Models::AdminPolicy, Cocina::Models::Collection] cocina_object
  # @return [Boolean] true if the object's files are always staged to the assembly location
  def self.stages_to_assembly?(cocina_object)
    CocinaSupport.geo?(cocina_object) || CocinaSupport.webarchive_seed?(cocina_object)
  end

  def self.staging_filepath(druid:, filepath:, staging_location: Settings.staging_location)
    File.join(staging_content_path(druid:, staging_location:), filepath)
  end

  def self.staging_content_path(druid:, staging_location: Settings.staging_location)
    druid_tree_folder = DruidTools::Druid.new(druid, staging_location).path
    File.join(druid_tree_folder, 'content')
  end

  # Creates the staging content directory for the object in the location it stages to, unless some staging location
  # already has the druid's folder.
  # @param [Cocina::Models::DRO, Cocina::Models::AdminPolicy, Cocina::Models::Collection] cocina_object
  def self.ensure_staging_folder(cocina_object:)
    druid = cocina_object.externalIdentifier
    return if locations.any? { |staging_location| File.directory?(DruidTools::Druid.new(druid, staging_location).path) }

    staging_location = stages_to_assembly?(cocina_object) ? Settings.assembly_location : Settings.staging_location
    FileUtils.mkdir_p(staging_content_path(druid:, staging_location:))
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
    locations.find { |staging_location| staged_files_in?(druid:, staging_location:) }
  end

  # Moves the druid's staged files from the deposit staging location to the assembly location (see
  # stages_to_assembly?), replacing any files already in the assembly location.
  def self.move_to_assembly(druid:)
    return unless staged_files_in?(druid:, staging_location: Settings.staging_location)

    assembly_druid_path = DruidTools::Druid.new(druid, Settings.assembly_location).path
    FileUtils.rm_rf(assembly_druid_path)
    FileUtils.mkdir_p(File.dirname(assembly_druid_path))
    FileUtils.mv(DruidTools::Druid.new(druid, Settings.staging_location).path, assembly_druid_path)
  end

  def self.staged_files_in?(druid:, staging_location:)
    content_path = staging_content_path(druid:, staging_location:)
    Dir.glob('**/*', base: content_path).any? { |path| File.file?(File.join(content_path, path)) }
  end
  private_class_method :staged_files_in?
end
