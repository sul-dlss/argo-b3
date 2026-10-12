# frozen_string_literal: true

# Policy for items.
class ItemPolicy < ApplicationPolicy
  # NOTE: Use ObjectPolicy for show?, edit?, and update? permissions.

  def new?
    # User belongs to a workgroup that has edit permissions on anything.
    Permission.permission_type_edit.exists?(
      workgroup: current_groups
    )
  end

  def create?
    true
  end
end
