class CreateContentFile < ActiveRecord::Migration[8.1]
  def change
    create_table :content_files do |t|
      t.belongs_to :content_file_set, null: false, foreign_key: true
      t.belongs_to :content_file_binary, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :label, null: false
      t.string :external_identifier
      t.string :language_tag
      t.string :use
      t.boolean :sdr_generated_text, null: false, default: false
      t.boolean :corrected_for_accessibility, null: false, default: false
      t.string :view, null: false
      t.string :download, null: false
      t.string :location
      t.boolean :publish, null: false
      t.boolean :preserve, null: false
      t.boolean :shelve, null: false
      t.integer :height
      t.integer :width
      t.timestamps
      t.index [:content_file_set_id, :position], unique: true
      t.index [:content_file_set_id, :content_file_binary_id], unique: true
    end
  end
end
