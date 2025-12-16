class CreateBulkAction < ActiveRecord::Migration[8.1]
  def change
    create_table :bulk_actions do |t|
      t.string :action_type, null: false
      t.string :status, null: false, default: 'created'
      t.string :log_filepath
      t.text :description
      t.integer :druid_count_total, null: false, default: 0
      t.integer :druid_count_success, null: false, default: 0
      t.integer :druid_count_fail, null: false, default: 0
      t.belongs_to :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
