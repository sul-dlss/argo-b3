class CreatePinnedObject < ActiveRecord::Migration[8.1]
  def change
    create_table :pinned_objects do |t|
      t.references :user, null: false, foreign_key: true
      t.string :druid, null: false

      t.timestamps
    end

    add_index :pinned_objects, %i[user_id druid], unique: true
  end
end
