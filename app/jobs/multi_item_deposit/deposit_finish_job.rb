# frozen_string_literal: true

module MultiItemDeposit
  # Batch on_finish callback for a Multi-Item Deposit's DepositJobs: completes initiating the deposit.
  class DepositFinishJob < ApplicationJob
    # @param multi_item_deposit_action [MultiItemDepositAction]
    def perform(multi_item_deposit_action:)
      multi_item_deposit_action.initiating_deposit_completed!
    end
  end
end
