# frozen_string_literal: true

# Policy for admin-related actions
class AdminPolicy < ApplicationPolicy
  alias_rule :impersonate?, :manage_permissions?, :groups?, to: :admin?

  # NOTE: Allowing admins is handled by precheck in ApplicationPolicy so returning false still allows admins.
end
