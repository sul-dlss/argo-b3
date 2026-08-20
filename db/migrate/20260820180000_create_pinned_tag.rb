# frozen_string_literal: true

# Creates pinned tags for users.
class CreatePinnedTag < ActiveRecord::Migration[8.1]
  def change
    create_table :pinned_tags do |t|
      t.references :user, null: false, foreign_key: true
      t.string :tag, null: false

      t.timestamps
    end

    add_index :pinned_tags, %i[user_id tag], unique: true
  end
end
