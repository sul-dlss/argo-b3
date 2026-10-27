# frozen_string_literal: true

# Policy for bulk actions
class BulkActionPolicy < ApplicationPolicy
  alias_rule :destroy?, :file?, :show?, to: :manage?

  # Pre-checks do not apply to scopes, so admins are checked here.
  relation_scope do |relation|
    admin? ? relation : relation.where(user:)
  end

  def manage?
    record.user_id == user.id
  end

  def cancel?
    # Only admins can cancel.
    false
  end
end
