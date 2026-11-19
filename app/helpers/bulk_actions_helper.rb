# frozen_string_literal: true

# Helper for listing bulk actions (the new bulk actions page and the header's bulk actions menu)
module BulkActionsHelper
  # @return [Hash{Symbol => Array<BulkActions::Config>}] the bulk action configs the current user may use, by section
  def available_bulk_action_sections
    BulkActions.available_sections { |admin_policy_rule| allowed_to?(admin_policy_rule, nil, with: AdminPolicy) }
  end
end
