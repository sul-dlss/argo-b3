# frozen_string_literal: true

module MultiItemDeposit
  # Renders the row for an Item Deposit in the summary table, with its structure errors and warnings as its status.
  class SummaryRowComponent < ApplicationComponent
    # @param item_deposit_action [ItemDepositAction]
    # @param file_count [Integer] the number of files discovered for the Item Deposit
    def initialize(item_deposit_action:, file_count:)
      @item_deposit_action = item_deposit_action
      @file_count = file_count
      super()
    end

    attr_reader :item_deposit_action, :file_count

    delegate :content_type_structure_warnings, :path, :structure_errors, to: :item_deposit_action

    def bare_druid
      DruidSupport.bare_druid_from(item_deposit_action.druid)
    end

    def content_type
      ContentTypeSupport.display_name(item_deposit_action.content_type)
    end

    def deposit_type
      t("multi_item_deposit.summary.deposit_types.#{item_deposit_action.deposit_type}")
    end

    def structure_errors_or_warnings?
      structure_errors.any? || content_type_structure_warnings.any?
    end
  end
end
