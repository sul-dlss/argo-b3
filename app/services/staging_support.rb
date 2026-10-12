# frozen_string_literal: true

# Methods for staging support, such as constructing file paths.
class StagingSupport
  def self.staging_filepath(druid:, filepath:)
    File.join(staging_content_path(druid:), filepath)
  end

  def self.staging_content_path(druid:)
    druid_tree_folder = DruidTools::Druid.new(druid, Settings.staging_location).path
    File.join(druid_tree_folder, 'content')
  end

  # @return [Boolean] true if the staging content directory for the druid exists and contains files
  #   (including in subdirectories)
  def self.staged_files?(druid:)
    content_path = staging_content_path(druid:)
    Dir.glob('**/*', base: content_path).any? { |path| File.file?(File.join(content_path, path)) }
  end
end
