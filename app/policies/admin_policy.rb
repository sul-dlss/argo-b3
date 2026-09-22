# frozen_string_literal: true

# Policy for admin-related actions
class AdminPolicy < ApplicationPolicy
  # Without skipping pre_check, these are always true when the user is an admin or impersonating an admin,
  # therefore skipping the actual policy logic.
  skip_pre_check :allow_admins, only: %i[impersonate? stop_impersonating?]

  alias_rule :manage_permissions?, :groups?, to: :admin?

  # can only start/update impersonating if an admin and not currently impersonating
  def impersonate?
    admin? && !Current.impersonating?
  end

  # can only stop impersonating if currently impersonating
  def stop_impersonating?
    Current.impersonating?
  end

  alias_rule :update_impersonation?, to: :impersonate?

  # NOTE: Allowing admins is handled by precheck in ApplicationPolicy so returning false still allows admins.
end
