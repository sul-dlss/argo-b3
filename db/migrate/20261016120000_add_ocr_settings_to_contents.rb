class AddOcrSettingsToContents < ActiveRecord::Migration[8.1]
  def change
    add_column :contents, :perform_ocr, :boolean, null: false, default: false
    add_column :contents, :ocr_languages, :jsonb, null: false, default: []
  end
end
