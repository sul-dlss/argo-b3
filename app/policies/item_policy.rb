# frozen_string_literal: true

# Policy for items.
# The record (for create?) responds to apo_druid and collection_druids, e.g., NewItemForm or ItemsRegistrationForm.
class ItemPolicy < ApplicationPolicy
  # NOTE: Use ObjectPolicy for show?, edit?, and update? permissions.

  def new?
    # User belongs to a workgroup that has edit permissions on anything.
    Permission.permission_type_edit.exists?(
      workgroup: current_groups
    )
  end

  # The user must be able to edit the APO and every collection.
  # Without a selected APO, the APO check is the same as new?, so that the missing APO is reported by form validation.
  # @return [Boolean]
  def create?
    apo_editable? && Array(record.collection_druids).all? { |collection_druid| collection_editable?(collection_druid) }
  end

  private

  # Unlike for an existing object, an edit permission on the APO's own governing APO does not suffice.
  def apo_editable?
    return new? if record.apo_druid.blank?

    edit_targets.include?(record.apo_druid)
  end

  # Editable when an edit permission targets the collection or its APO.
  def collection_editable?(collection_druid)
    return true if edit_targets.include?(collection_druid)

    allowed_to?(:edit?, Sdr::Repository.find_solr(druid: collection_druid), with: ObjectPolicy)
  rescue Sdr::Repository::NotFoundResponse
    false
  end

  def edit_targets
    @edit_targets ||= Permissions::UserScope.new(groups: current_groups).edit_targets
  end
end
