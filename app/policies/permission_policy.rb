# frozen_string_literal: true

# Policy for managing permissions
class PermissionPolicy < ApplicationPolicy
  # NOTE: Allowing admins is handled by precheck in ApplicationPolicy so returning false still allows admins.
  def index?
    false
  end
end
