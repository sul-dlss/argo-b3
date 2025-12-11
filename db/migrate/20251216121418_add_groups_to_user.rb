class AddGroupsToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :groups, :string, array: true, default: []
  end
end
