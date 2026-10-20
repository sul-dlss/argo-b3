# frozen_string_literal: true

# Policy for Multi-Item Deposits.
class MultiItemDepositActionPolicy < ApplicationPolicy
  alias_rule :update?, :edit?, :show?, to: :manage?

  def manage?
    record.user_id == user.id
  end
end
