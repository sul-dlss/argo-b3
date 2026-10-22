# frozen_string_literal: true

module MultiItemDeposit
  # Form for the deposit step of a multi-item deposit.
  class DepositForm < ApplicationForm
    INITIAL_VERSION_DESCRIPTION = 'Initial version'

    inherit_attributes_from MultiItemDepositAction, only: %i[version_description]
    normalizes_whitespace :version_description

    # The disabled version description input is not submitted, so it is set for initial deposits.
    before_validation :set_initial_version_description, if: -> { multi_item_deposit_action&.all_initial_versions? }
    validates :version_description, presence: true

    # Not an attribute so that it is not a permitted param.
    attr_accessor :multi_item_deposit_action

    def from_model(multi_item_deposit_action)
      super
      self.multi_item_deposit_action = multi_item_deposit_action
      set_initial_version_description if multi_item_deposit_action.all_initial_versions?
      self
    end

    private

    def set_initial_version_description
      self.version_description = INITIAL_VERSION_DESCRIPTION
    end
  end
end
