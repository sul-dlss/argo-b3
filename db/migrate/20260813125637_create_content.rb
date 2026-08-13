class CreateContent < ActiveRecord::Migration[8.1]
  def change
    create_table :contents do |t|
      t.string :druid, null: false
      t.string :lock, null: false
      t.timestamps
      t.index [:druid, :lock], unique: true
    end
  end
end
