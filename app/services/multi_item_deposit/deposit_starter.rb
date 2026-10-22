# frozen_string_literal: true

module MultiItemDeposit
  # Starts the deposit for a Multi-Item Deposit: saves the version description and enqueues a DepositJob,
  # which completes initiating the deposit.
  class DepositStarter
    def self.call(...)
      new(...).call
    end

    # @param multi_item_deposit_action [MultiItemDepositAction]
    # @param deposit_form [DepositForm] a valid deposit form
    # @param effective_groups [Array<String>] the requesting user's authorization workgroups
    def initialize(multi_item_deposit_action:, deposit_form:, effective_groups:)
      @multi_item_deposit_action = multi_item_deposit_action
      @deposit_form = deposit_form
      @effective_groups = effective_groups
    end

    def call
      multi_item_deposit_action.version_description = deposit_form.version_description
      multi_item_deposit_action.initiating_deposit_started!
      DepositJob.perform_later(multi_item_deposit_action:, effective_groups:)
    end

    private

    attr_reader :multi_item_deposit_action, :deposit_form, :effective_groups
  end
end
