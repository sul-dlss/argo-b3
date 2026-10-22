# frozen_string_literal: true

module Dashboard
  # Render the table of a user's most recent Multi-Item Deposits on the dashboard.
  class MultiItemDepositsTableComponent < ApplicationComponent
    def initialize(multi_item_deposit_actions:)
      @multi_item_deposit_actions = multi_item_deposit_actions
      super()
    end

    attr_reader :multi_item_deposit_actions

    def label
      I18n.t('multi_item_deposit_actions.history.heading')
    end

    def render?
      multi_item_deposit_actions.any?
    end
  end
end
