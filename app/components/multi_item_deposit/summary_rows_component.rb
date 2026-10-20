# frozen_string_literal: true

module MultiItemDeposit
  # Renders the rows for an Item Deposit in the summary table: its summary, followed by a row listing any
  # structure errors and warnings.
  class SummaryRowsComponent < ApplicationComponent
    # @param item_deposit_action [ItemDepositAction]
    # @param file_count [Integer] the number of files discovered for the Item Deposit
    def initialize(item_deposit_action:, file_count:)
      @item_deposit_action = item_deposit_action
      @file_count = file_count
      super()
    end

    attr_reader :item_deposit_action, :file_count

    delegate :content_type, :content_type_structure_warnings, :structure_errors, to: :item_deposit_action

    def bare_druid
      DruidSupport.bare_druid_from(item_deposit_action.druid)
    end

    def deposit_type
      deposit_type = item_deposit_action.initial_version? ? :new_item : :redeposit
      t("multi_item_deposit.summary.deposit_types.#{deposit_type}")
    end

    def structure_errors_or_warnings?
      structure_errors.any? || content_type_structure_warnings.any?
    end
  end
end
