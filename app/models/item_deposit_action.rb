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
  scope :with_structure_errors, lambda {
    where("structural_csv_errors <> '[]'::jsonb").or(where("content_type_structure_errors <> '[]'::jsonb"))
  }

  def structure_errors
    structural_csv_errors + content_type_structure_errors
  end
end
