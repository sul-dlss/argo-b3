# frozen_string_literal: true

# Policy for Multi-Item Deposits.
class MultiItemDepositActionPolicy < ApplicationPolicy
  alias_rule :update?, :edit?, :show?, to: :manage?

  # Pre-checks do not apply to scopes, so admins are checked here.
  relation_scope do |relation|
    admin? ? relation : relation.where(user:)
  end

  def manage?
    record.user_id == user.id
  end
end
