# frozen_string_literal: true

# Adds the mount path for binaries whose file_location is mount.
class AddMountPathToContentFileBinary < ActiveRecord::Migration[8.1]
  def change
    add_column :content_file_binaries, :mount_path, :string
  end
end
