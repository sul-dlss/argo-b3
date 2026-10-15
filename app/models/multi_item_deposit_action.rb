# frozen_string_literal: true

# Model for a Multi-Item Deposit: a user-run deposit of many Items, carried out in steps.
# A step is complete when its *_completed_at is set (by its state machine's transition);
# failures are recorded on the ItemDepositActions.
class MultiItemDepositAction < ApplicationRecord
  belongs_to :user
  has_many :item_deposit_actions, dependent: :destroy

  enum :file_location, { globus: 'globus', mount: 'mount' }, prefix: true, validate: true
  enum :step, { discovery: 'discovery', structure: 'structure', deposit: 'deposit', submitted: 'submitted' },
       prefix: true, validate: true
  enum :structural_metadata_csv_source, { mount: 'mount', upload: 'upload' }, prefix: true,
                                                                              validate: { allow_nil: true }

  state_machine :discovery_state, initial: :discovery_not_in_progress do
    event :discovery_started do
      transition discovery_not_in_progress: :discovering
    end

    event :discovery_completed do
      transition discovering: :discovery_not_in_progress
    end

    before_transition on: :discovery_started do |multi_item_deposit_action|
      multi_item_deposit_action.assign_attributes(discovery_started_at: Time.current, discovery_completed_at: nil)
    end

    before_transition on: :discovery_completed do |multi_item_deposit_action|
      multi_item_deposit_action.discovery_completed_at = Time.current
    end
  end

  state_machine :structuring_state, initial: :structuring_not_in_progress do
    event :structuring_started do
      transition structuring_not_in_progress: :structuring
    end

    event :structuring_completed do
      transition structuring: :structuring_not_in_progress
    end

    before_transition on: :structuring_started do |multi_item_deposit_action|
      multi_item_deposit_action.assign_attributes(structuring_started_at: Time.current, structuring_completed_at: nil)
    end

    before_transition on: :structuring_completed do |multi_item_deposit_action|
      multi_item_deposit_action.structuring_completed_at = Time.current
    end
  end

  state_machine :initiating_deposit_state, initial: :initiating_deposit_not_in_progress do
    event :initiating_deposit_started do
      transition initiating_deposit_not_in_progress: :initiating_depositing
    end

    event :initiating_deposit_completed do
      transition initiating_depositing: :initiating_deposit_not_in_progress
    end

    before_transition on: :initiating_deposit_started do |multi_item_deposit_action|
      multi_item_deposit_action.assign_attributes(initiating_deposit_started_at: Time.current,
                                                  initiating_deposit_completed_at: nil)
    end

    before_transition on: :initiating_deposit_completed do |multi_item_deposit_action|
      multi_item_deposit_action.initiating_deposit_completed_at = Time.current
    end
  end
end
