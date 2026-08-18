# frozen_string_literal: true

# Policy for admin-related actions
class AdminPolicy < ApplicationPolicy
  # NOTE: Allowing admins is handled by precheck in ApplicationPolicy so returning false still allows admins.
  def groups?
    false
  end

  def impersonate?
    false
  end

  def manage_permissions?
    false
  end
end
