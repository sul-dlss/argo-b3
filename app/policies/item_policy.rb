# frozen_string_literal: true

# Policy for items.
class ItemPolicy < ApplicationPolicy
  alias_rule :update?, to: :edit?

  def new?
    # User belongs to a workgroup that has edit permissions on anything.
    Permission.permission_type_edit.exists?(
      workgroup: user.groups
    )
  end

  def create?
    true
  end

  def edit?
    true
  end
end
