class MoveDimensionsToContentFileBinaries < ActiveRecord::Migration[8.1]
  def up
    add_column :content_file_binaries, :height, :integer
    add_column :content_file_binaries, :width, :integer

    execute <<~SQL.squish
      UPDATE content_file_binaries
      SET height = content_files.height, width = content_files.width
      FROM content_files
      WHERE content_files.content_file_binary_id = content_file_binaries.id
        AND (content_files.height IS NOT NULL OR content_files.width IS NOT NULL)
    SQL

    remove_column :content_files, :height
    remove_column :content_files, :width
  end

  def down
    add_column :content_files, :height, :integer
    add_column :content_files, :width, :integer

    execute <<~SQL.squish
      UPDATE content_files
      SET height = content_file_binaries.height, width = content_file_binaries.width
      FROM content_file_binaries
      WHERE content_files.content_file_binary_id = content_file_binaries.id
    SQL

    remove_column :content_file_binaries, :height
    remove_column :content_file_binaries, :width
  end
end
