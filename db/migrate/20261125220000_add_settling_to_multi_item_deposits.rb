# frozen_string_literal: true

class AddSettlingToMultiItemDeposits < ActiveRecord::Migration[8.1]
  def change
    # A MID Item Deposit's Tracked Deposit counts toward its Multi-Item Deposit's settled Notification.
    add_reference :tracked_deposits, :item_deposit_action, foreign_key: { on_delete: :cascade }
    # When the Multi-Item Deposit last settled; nil while it is unsettled.
    add_column :multi_item_deposit_actions, :settled_at, :datetime
    # When a settled email went out; after that, settling no longer notifies.
    add_column :multi_item_deposit_actions, :settled_email_sent_at, :datetime

    reversible do |direction|
      # Multi-Item Deposits submitted before settling was tracked are not notified.
      direction.up do
        execute <<~SQL.squish
          UPDATE multi_item_deposit_actions SET settled_email_sent_at = CURRENT_TIMESTAMP WHERE step = 'submitted'
        SQL
      end
    end
  end
end
