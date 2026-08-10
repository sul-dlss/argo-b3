# frozen_string_literal: true

# Policy for items.
class ItemPolicy < ApplicationPolicy
  def new?
    true
  end

  def create?
    true
  end
end
