# frozen_string_literal: true

# Policy for Multi-Item Deposits.
class MultiItemDepositActionPolicy < ApplicationPolicy
  def edit?
    record.user_id == user.id
  end
end
