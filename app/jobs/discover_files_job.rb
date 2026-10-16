# frozen_string_literal: true

# Job that discovers the files on a mount and records them as ContentFileBinaries for a Content.
# Structuring the binaries into ContentFileSets and ContentFiles is left to the Contents::Populators.
class DiscoverFilesJob < ApplicationJob
  # @param [Content] content
  # @param [String] mount_path the directory on the mount to discover files in (recursively)
  def perform(content:, mount_path:)
    Contents::MountDiscoverer.call(content:, mount_path:)

    content.discovery_completed!
  end
end
