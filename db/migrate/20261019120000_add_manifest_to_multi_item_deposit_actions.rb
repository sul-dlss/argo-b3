class AddManifestToMultiItemDepositActions < ActiveRecord::Migration[8.1]
  def change
    add_column :multi_item_deposit_actions, :manifest_source, :string, null: false, default: 'upload'
    add_column :multi_item_deposit_actions, :manifest_csv, :text
  end
end
