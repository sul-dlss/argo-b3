# frozen_string_literal: true

module MultiItemDeposit
  # Batch on_finish callback for a Multi-Item Deposit's DiscoverFilesJobs: completes Discovery and notifies the owner.
  class DiscoverFilesFinishJob < ApplicationJob
    queue_as :real_time

    # @param multi_item_deposit_action [MultiItemDepositAction]
    def perform(multi_item_deposit_action:)
      multi_item_deposit_action.size = size_for(multi_item_deposit_action)
      multi_item_deposit_action.discovery_completed!

      notify_finished(multi_item_deposit_action)
    end

    private

    def notify_finished(multi_item_deposit_action)
      error_count = multi_item_deposit_action.item_deposit_actions.with_discovery_errors.count
      deliver_notification(MultiItemDepositDiscoveryFinishedNotifier, recipient: multi_item_deposit_action.user,
                                                                      record: multi_item_deposit_action,
                                                                      name: multi_item_deposit_action.name,
                                                                      error_count:)
    end

    def size_for(multi_item_deposit_action)
      ContentFileBinary.where(content_id: multi_item_deposit_action.item_deposit_actions.select(:content_id)).sum(:size)
    end
  end
end
