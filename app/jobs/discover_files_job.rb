# frozen_string_literal: true

# Job that discovers the files on a mount and records them as ContentFileBinaries for a Content.
# Files that should be ignored are skipped and never become records.
# Structuring the binaries into ContentFileSets and ContentFiles is left to the Contents::Populators.
class DiscoverFilesJob < ApplicationJob
  # @param [Content] content
  # @param [String] mount_path the directory on the mount to discover files in (recursively)
  def perform(content:, mount_path:)
    @content = content
    @mount_path = mount_path

    filepaths.each do |filepath|
      next if IgnoreFileService.call(filepath:)

      build_content_file_binary(filepath:)
    end

    content.discovery_completed!
  end

  private

  attr_reader :content, :mount_path

  # @return [Array<String>] filepaths relative to the mount path
  def filepaths
    # File::FNM_DOTMATCH matches .<filename> files.
    Dir.glob('**/*', File::FNM_DOTMATCH, base: mount_path)
       .select { |filepath| File.file?(File.join(mount_path, filepath)) }
  end

  def build_content_file_binary(filepath:) # rubocop:disable Metrics/AbcSize
    content_file_binary = content.content_file_binaries.find_or_initialize_by(filepath:)
    full_filepath = File.join(mount_path, filepath)
    content_file_binary.file_location = :mount
    content_file_binary.mount_path = mount_path
    content_file_binary.size = File.size(full_filepath)
    content_file_binary.mime_type = Marcel::MimeType.for(Pathname.new(full_filepath), name: filepath)
    content_file_binary.sha1_digest = nil
    content_file_binary.md5_digest = nil
    content_file_binary.save!
  end
end
