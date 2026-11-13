# frozen_string_literal: true

class AddManageFilesFlowToContents < ActiveRecord::Migration[8.1]
  def change
    change_table :contents, bulk: true do |t|
      t.string :step, null: false, default: 'details'
      t.string :structuring_state, null: false, default: 'structuring_not_in_progress'
      # The item details chosen while managing files, until they are saved to the object.
      t.string :content_type
      t.string :viewing_direction
      t.boolean :with_embargo
      t.datetime :embargo_release_date
      t.string :access_view
      t.string :access_download
      t.string :access_location
      t.string :embargo_view
      t.string :embargo_download
      t.string :embargo_location
      t.boolean :overwrite_file_access
      t.string :version_description
    end
  end
end
