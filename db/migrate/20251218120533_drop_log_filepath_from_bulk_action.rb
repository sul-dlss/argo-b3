class DropLogFilepathFromBulkAction < ActiveRecord::Migration[8.1]
  def change
    remove_column :bulk_actions, :log_filepath, :string
  end
end
