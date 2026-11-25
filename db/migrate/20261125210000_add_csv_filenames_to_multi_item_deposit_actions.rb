# frozen_string_literal: true

class AddCsvFilenamesToMultiItemDepositActions < ActiveRecord::Migration[8.1]
  def change
    # The filenames of the uploaded manifest and structural metadata CSV, shown when they are kept.
    add_column :multi_item_deposit_actions, :manifest_filename, :string
    add_column :multi_item_deposit_actions, :structural_metadata_csv_filename, :string

    # Uploaded CSVs saved before filenames were kept get default filenames, so every uploaded CSV has one.
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE multi_item_deposit_actions SET manifest_filename = 'manifest.csv'
          WHERE manifest_source = 'upload' AND manifest_csv IS NOT NULL
        SQL
        execute <<~SQL.squish
          UPDATE multi_item_deposit_actions SET structural_metadata_csv_filename = 'structural_metadata.csv'
          WHERE structural_metadata_csv_source = 'upload' AND structural_metadata_csv IS NOT NULL
        SQL
      end
    end
  end
end
