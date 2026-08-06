# frozen_string_literal: true

# Policy for digital objects.
class ObjectPolicy < ApplicationPolicy
  alias_rule :show_json?, to: :show?

  def show?
    true
  end

  # Until authorization requirements are determined, only allowing admins.
  def edit?
    false
  end

  def edit_description?
    admin?
  end
end
