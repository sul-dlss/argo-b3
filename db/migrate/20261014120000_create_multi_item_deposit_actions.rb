class CreateMultiItemDepositActions < ActiveRecord::Migration[8.1]
  def change
    create_table :multi_item_deposit_actions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :description
      t.string :file_location, null: false, default: 'mount'
      t.string :mount_path
      t.string :step, null: false, default: 'discovery'
      t.string :discovery_state, null: false, default: 'discovery_not_in_progress'
      t.string :structuring_state, null: false, default: 'structuring_not_in_progress'
      t.string :initiating_deposit_state, null: false, default: 'initiating_deposit_not_in_progress'
      t.text :structural_metadata_csv
      t.string :structural_metadata_csv_source
      t.boolean :publish_preserve_all, null: false, default: false
      t.bigint :size
      t.string :version_description
      t.boolean :perform_ocr, null: false, default: false
      t.jsonb :ocr_languages, null: false, default: []
      t.datetime :discovery_started_at
      t.datetime :discovery_completed_at
      t.datetime :structuring_started_at
      t.datetime :structuring_completed_at
      t.datetime :initiating_deposit_started_at
      t.datetime :initiating_deposit_completed_at
      t.timestamps
    end

    create_table :item_deposit_actions do |t|
      t.references :multi_item_deposit_action, null: false, foreign_key: true, index: false
      t.references :content, foreign_key: { on_delete: :nullify }
      t.string :druid, null: false, index: true
      t.string :path, null: false
      t.integer :manifest_line_number, null: false
      t.jsonb :discovery_errors, null: false, default: []
      t.jsonb :discovery_warnings, null: false, default: []
      t.jsonb :structural_csv_errors, null: false, default: []
      t.jsonb :content_type_structure_errors, null: false, default: []
      t.jsonb :content_type_structure_warnings, null: false, default: []
      t.jsonb :deposit_errors, null: false, default: []
      t.jsonb :file_changes, null: false, default: {}
      t.boolean :initial_version
      t.string :content_type
      t.timestamps
      t.index %i[multi_item_deposit_action_id druid], unique: true, name: 'index_item_deposit_actions_on_multi_item_deposit_and_druid'
    end
  end
end
