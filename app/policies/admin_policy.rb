# frozen_string_literal: true

# Policy for admin-related actions
class AdminPolicy < ApplicationPolicy
  def groups?
    # Allowing admins is handled by precheck in ApplicationPolicy
    false
  end
end
