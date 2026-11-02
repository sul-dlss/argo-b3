# frozen_string_literal: true

# Job that discovers the files on a mount and records them as ContentFileBinaries for a Content.
# Structuring the binaries into ContentFileSets and ContentFiles is left to the Contents::Populators.
class DiscoverFilesJob < ApplicationJob
  queue_as :real_time

  # @param [Content] content
  # @param [String] mount_path the directory on the mount to discover files in (recursively)
  # @param [Symbol] file_location the file location of the binaries (:mount or :globus, which is also mounted)
  def perform(content:, mount_path:, file_location: :mount)
    Contents::MountDiscoverer.call(content:, mount_path:, file_location:)

    content.discovery_completed!
  end
end
