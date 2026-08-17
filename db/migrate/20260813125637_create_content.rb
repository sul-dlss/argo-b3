class CreateContent < ActiveRecord::Migration[8.1]
  def change
    create_table :contents do |t|
      t.string :druid, null: false
      t.string :lock, null: false
      t.string :staging_state, null: false, default: 'staging_not_in_progress'
      t.boolean :immutable, null: false, default: true
      t.timestamps
      t.index [:druid, :lock, :immutable], unique: true
    end
  end
end
