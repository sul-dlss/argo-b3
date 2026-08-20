class CreatePinnedSearch < ActiveRecord::Migration[8.1]
  def change
    create_table :pinned_searches do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :search_form_attributes, null: false
      t.string :search_form_md5, null: false

      t.timestamps
    end

    add_index :pinned_searches, %i[user_id search_form_md5], unique: true
  end
end
