# frozen_string_literal: true

class AddErrorTimesToTrackedDeposits < ActiveRecord::Migration[8.1]
  def change
    # When staging failed during the Deposit; nil once staging is retried.
    add_column :tracked_deposits, :staging_failed_at, :datetime
    # When a Process went into error; nil once no Process is in error.
    add_column :tracked_deposits, :process_errored_at, :datetime
  end
end
