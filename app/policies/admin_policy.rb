# frozen_string_literal: true

# Policy for admin-related actions
class AdminPolicy < ApplicationPolicy
  alias_rule :manage_permissions?, :groups?, to: :admin?

  def impersonate?
    admin? || Current.impersonating?
  end

  alias_rule :update_impersonation?, :stop_impersonating?, to: :impersonate?

  # NOTE: Allowing admins is handled by precheck in ApplicationPolicy so returning false still allows admins.
end
