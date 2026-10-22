# frozen_string_literal: true

module MultiItemDeposit
  # Renders the discovery errors and warnings for a Multi-Item Deposit's Item Deposits.
  class DiscoveryErrorDetailsTableComponent < ApplicationComponent
    def initialize(multi_item_deposit_action:)
      @multi_item_deposit_action = multi_item_deposit_action
      super()
    end

    def render?
      item_deposit_actions.exists?
    end

    # @return [Array<ItemDepositAction>] the Item Deposits with discovery errors or warnings
    def item_deposit_actions
      @item_deposit_actions ||= @multi_item_deposit_action.item_deposit_actions_with_discovery_errors_or_warnings
    end

    def bare_druid(item_deposit_action)
      DruidSupport.bare_druid_from(item_deposit_action.druid)
    end

    def label
      t('multi_item_deposit.error_details.label')
    end
  end
end
