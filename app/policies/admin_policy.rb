# frozen_string_literal: true

# Policy for admin-related actions
class AdminPolicy < ApplicationPolicy
  alias_rule :manage_permissions?, :groups?, to: :admin?

  # can only start/update impersonating if an admin and not currently impersonating
  def impersonate?
    admin? || !Current.impersonating?
  end

  # can only stop impersonating if an admin and currently impersonating
  def stop_impersonating?
    admin? || Current.impersonating?
  end

  alias_rule :update_impersonation?, to: :impersonate?

  # NOTE: Allowing admins is handled by precheck in ApplicationPolicy so returning false still allows admins.
end
