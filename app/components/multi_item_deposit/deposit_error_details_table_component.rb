# frozen_string_literal: true

module MultiItemDeposit
  # Renders the deposit errors for a Multi-Item Deposit's Item Deposits.
  class DepositErrorDetailsTableComponent < ApplicationComponent
    def initialize(multi_item_deposit_action:)
      @multi_item_deposit_action = multi_item_deposit_action
      super()
    end

    def render?
      item_deposit_actions_with_deposit_errors.exists?
    end

    # @return [ActiveRecord::Relation<ItemDepositAction>] the Item Deposits with deposit errors in manifest order
    def item_deposit_actions_with_deposit_errors
      @item_deposit_actions_with_deposit_errors ||=
        @multi_item_deposit_action.item_deposit_actions.with_deposit_errors.order(:manifest_line_number)
    end

    def bare_druid(item_deposit_action)
      DruidSupport.bare_druid_from(item_deposit_action.druid)
    end

    def label
      t('multi_item_deposit.error_details.label')
    end
  end
end
