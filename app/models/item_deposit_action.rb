# frozen_string_literal: true

# Model for an Item Deposit: one Item within a Multi-Item Deposit.
class ItemDepositAction < ApplicationRecord
  belongs_to :multi_item_deposit_action
  delegate :user, :mount_path, to: :multi_item_deposit_action
  # The Content may be destroyed independently (e.g., by ContentCleanupJob), which nullifies content_id.
  belongs_to :content, optional: true

  # where.not(discovery_errors: []) would be NOT IN (), so the jsonb arrays are compared directly.
  scope :with_discovery_errors, -> { where("discovery_errors <> '[]'::jsonb") }
  scope :with_discovery_warnings, -> { where("discovery_warnings <> '[]'::jsonb") }
end
