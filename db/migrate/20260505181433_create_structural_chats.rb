class CreateStructuralChats < ActiveRecord::Migration[8.1]
  def change
    create_table :structural_chats do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.string :druid, null: false
      t.timestamps
      t.index :druid
    end
  end
end
