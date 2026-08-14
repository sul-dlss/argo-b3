class CreateContentFileBinary < ActiveRecord::Migration[8.1]
  def change
    create_table :content_file_binaries do |t|
      t.belongs_to :content, null: false, foreign_key: true
      t.string :file_location, null: false
      t.string :filepath, null: false
      t.string :basename, null: false
      t.string :extname, null: false
      t.string :path_parts, array: true, null: false, default: []
      t.bigint :size
      t.string :md5_digest
      t.string :sha1_digest
      t.timestamps
      t.index [:content_id, :filepath], unique: true
    end
  end
end
