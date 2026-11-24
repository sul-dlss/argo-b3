# frozen_string_literal: true

module MultiItemDeposit
  # Batch on_finish callback for a Multi-Item Deposit's StructureJobs: completes File Check and notifies the owner.
  class StructureFinishJob < ApplicationJob
    queue_as :real_time

    # @param multi_item_deposit_action [MultiItemDepositAction]
    def perform(multi_item_deposit_action:)
      multi_item_deposit_action.structuring_completed!

      notify_finished(multi_item_deposit_action)
    end

    private

    def notify_finished(multi_item_deposit_action)
      item_deposit_actions = multi_item_deposit_action.item_deposit_actions
      error_count = item_deposit_actions.with_structure_errors.count
      deliver_notification(MultiItemDepositFileCheckFinishedNotifier, recipient: multi_item_deposit_action.user,
                                                                      record: multi_item_deposit_action,
                                                                      name: multi_item_deposit_action.name,
                                                                      error_count:,
                                                                      item_deposit_count: item_deposit_actions.count)
    end
  end
end
