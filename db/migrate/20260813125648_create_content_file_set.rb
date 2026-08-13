class CreateContentFileSet < ActiveRecord::Migration[8.1]
  def change
    create_table :content_file_sets do |t|
      t.belongs_to :content, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :file_set_type, null: false
      t.string :label, null: false
      t.string :external_identifier
      t.timestamps
      t.index [:content_id, :position], unique: true
    end
  end
end
