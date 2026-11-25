# frozen_string_literal: true

class CreateTrackedDeposits < ActiveRecord::Migration[8.1]
  def change
    create_table :tracked_deposits do |t|
      t.string :druid, null: false
      t.integer :version, null: false
      # The depositing user, who is notified of the Deposit's outcome.
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :tracked_deposits, %i[druid version], unique: true
  end
end
