# frozen_string_literal: true

# Policy for registering collections. The record (for create?) is the druid of the selected governing APO.
class CollectionPolicy < ApplicationPolicy
  # NOTE: Use ObjectPolicy for show?, edit?, and update? permissions.

  # Permission targets are not typed (they may be APOs or collections), so any edit permission
  # grants access to the form; the APO options and create? limit it to APOs the user can edit.
  # @return [Boolean] true if the user has edit permission on any target
  def new?
    permission_scope.edit_targets.any?
  end

  # Without a selected APO, this is the same as new?, so that the missing APO is reported by form validation.
  # @return [Boolean] true if the user has edit permission on the selected APO
  def create?
    return new? if record.blank?

    permission_scope.edit_targets.include?(record)
  end

  private

  # @return [Permissions::UserScope]
  def permission_scope
    @permission_scope ||= Permissions::UserScope.new(groups: current_groups)
  end
end
