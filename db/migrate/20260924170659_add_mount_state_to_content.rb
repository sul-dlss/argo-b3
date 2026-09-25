class AddMountStateToContent < ActiveRecord::Migration[8.1]
  def change
    add_column :contents, :mount_state, :string, default: 'discovery_not_in_progress', null: false
  end
end
