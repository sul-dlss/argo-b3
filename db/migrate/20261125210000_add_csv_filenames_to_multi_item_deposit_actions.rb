# frozen_string_literal: true

class AddCsvFilenamesToMultiItemDepositActions < ActiveRecord::Migration[8.1]
  def change
    # The filenames of the uploaded manifest and structural metadata CSV, shown when they are kept.
    add_column :multi_item_deposit_actions, :manifest_filename, :string
    add_column :multi_item_deposit_actions, :structural_metadata_csv_filename, :string
  end
end
