# frozen_string_literal: true

# Policy for registering and editing collections.
# The record for create? is the druid of the selected governing APO.
# The record for update_apo? is a collection model (e.g., EditCollectionForm) with the requested changes.
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

  # The user must be able to edit the APO the collection is being moved to; the current APO may be kept.
  # Unlike for an existing object, an edit permission on the APO's own governing APO does not suffice.
  # @return [Boolean]
  def update_apo?
    record.apo_druid == record.previous_cocina_object.administrative.hasAdminPolicy ||
      permission_scope.edit_targets.include?(record.apo_druid)
  end
end
