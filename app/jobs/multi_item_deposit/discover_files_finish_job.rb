# frozen_string_literal: true

module MultiItemDeposit
  # Batch on_finish callback for a Multi-Item Deposit's DiscoverFilesJobs: completes discovery and notifies the user.
  class DiscoverFilesFinishJob < ApplicationJob
    queue_as :real_time

    # @param multi_item_deposit_action [MultiItemDepositAction]
    def perform(multi_item_deposit_action:)
      multi_item_deposit_action.size = size_for(multi_item_deposit_action)
      multi_item_deposit_action.discovery_completed!

      broadcast_toast(title: I18n.t('multi_item_deposit.discover_files.toasts.completed'),
                      user: multi_item_deposit_action.user)
    end

    private

    def size_for(multi_item_deposit_action)
      ContentFileBinary.where(content_id: multi_item_deposit_action.item_deposit_actions.select(:content_id)).sum(:size)
    end
  end
end
