# frozen_string_literal: true

# Policy for Multi-Item Deposits.
class MultiItemDepositActionPolicy < ApplicationPolicy
  alias_rule :update?, to: :edit?

  def edit?
    record.user_id == user.id
  end
end
