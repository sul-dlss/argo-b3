# frozen_string_literal: true

module MultiItemDeposit
  # Batch on_finish callback for a Multi-Item Deposit's StructureJobs: completes structuring and notifies the user.
  class StructureFinishJob < ApplicationJob
    # @param multi_item_deposit_action [MultiItemDepositAction]
    def perform(multi_item_deposit_action:)
      multi_item_deposit_action.structuring_completed!

      broadcast_toast(title: I18n.t('multi_item_deposit.structure.toasts.completed'),
                      user: multi_item_deposit_action.user)
    end
  end
end
