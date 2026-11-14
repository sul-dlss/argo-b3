# frozen_string_literal: true

module MultiItemDeposit
  # Renders the Discard button in the footer of a Multi-Item Deposit step's form, which deletes the deposit
  # after the user confirms.
  class DiscardButtonComponent < ApplicationComponent
    def initialize(multi_item_deposit_action:)
      @multi_item_deposit_action = multi_item_deposit_action
      super()
    end

    def path
      helpers.multi_item_deposit_action_path(@multi_item_deposit_action)
    end

    def confirm
      t('edit.multi_item_deposits.edit.buttons.discard_confirm', name: @multi_item_deposit_action.name)
    end
  end
end
