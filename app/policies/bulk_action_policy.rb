# frozen_string_literal: true

# Policy for bulk actions
class BulkActionPolicy < ApplicationPolicy
  alias_rule :destroy?, :file?, to: :manage?

  def manage?
    record.user_id == user.id
  end
end
