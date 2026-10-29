class AddGlobusPathToMultiItemDepositActions < ActiveRecord::Migration[8.1]
  def change
    add_column :multi_item_deposit_actions, :globus_path, :string
  end
end
