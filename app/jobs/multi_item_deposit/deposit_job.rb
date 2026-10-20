# frozen_string_literal: true

module MultiItemDeposit
  # Deposit for one Item Deposit: opens a version as necessary and stages its mutable Content for accessioning.
  class DepositJob < ApplicationJob
    # @param item_deposit_action [ItemDepositAction]
    def perform(item_deposit_action:)
      # To be implemented (https://github.com/sul-dlss/argo-b3/issues/885).
    end
  end
end
