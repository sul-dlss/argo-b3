# frozen_string_literal: true

module Show
  # Component for the status box's Deposit dropdown: a form to describe the Draft's version and deposit it.
  class DepositDropdownComponent < ApplicationComponent
    # @param deposit_form [DepositDraftForm] prefilled with the open version's description and the page's lock
    # @param druid [String] the druid of the object
    # @param disabled [Boolean] true if the user can't deposit, so the dropdown can't be opened
    def initialize(deposit_form:, druid:, disabled: false)
      @deposit_form = deposit_form
      @druid = druid
      @disabled = disabled
      super()
    end

    attr_reader :deposit_form, :druid, :disabled

    def toggle_data
      {
        'bs-toggle': 'dropdown',
        # Clicking in the form (e.g., its label) doesn't close the dropdown; Cancel does.
        'bs-auto-close': 'outside',
        # Fixed, so that the menu isn't clipped by the status box, which scrolls its overflow.
        'bs-popper-config': { strategy: 'fixed' }.to_json,
        'dropdown-form-target': 'toggle'
      }
    end
  end
end
