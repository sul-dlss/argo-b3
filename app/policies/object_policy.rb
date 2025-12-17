# frozen_string_literal: true

# Policy for digital objects.
class ObjectPolicy < ApplicationPolicy
  # Until authorization requirements are determined, only allowing admins.
  def show?
    false
  end

  def edit?
    false
  end
end
