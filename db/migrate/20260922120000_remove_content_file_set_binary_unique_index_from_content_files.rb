# frozen_string_literal: true

# Cocina permits a file set to reference the same filename more than once, which Contents::Builder
# maps to multiple ContentFiles sharing a single ContentFileBinary within the same ContentFileSet.
class RemoveContentFileSetBinaryUniqueIndexFromContentFiles < ActiveRecord::Migration[8.1]
  def change
    remove_index :content_files, %i[content_file_set_id content_file_binary_id], unique: true
  end
end
