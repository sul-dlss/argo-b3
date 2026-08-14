# frozen_string_literal: true

# Policy for items.
class ItemPolicy < ApplicationPolicy
  alias_rule :update?, to: :edit?

  def new?
    true
  end

  def create?
    true
  end

  def edit?
    true
  end
end
