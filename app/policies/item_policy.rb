# frozen_string_literal: true

# Policy for items.
# The record for create? responds to apo_druid and collection_druids, e.g., NewItemForm or ItemsRegistrationForm.
# The record for add_to_collections? and update_apo? is an item model (e.g., EditItemForm) with the requested changes.
class ItemPolicy < ApplicationPolicy
  # NOTE: Use ObjectPolicy for show?, edit?, and update? permissions.

  def new?
    # User belongs to a workgroup that has edit permissions on anything.
    permission_scope.edit_targets.any?
  end

  # The user must be able to edit the APO and every collection.
  # Without a selected APO, the APO check is the same as new?, so that the missing APO is reported by form validation.
  # @return [Boolean]
  def create?
    apo_editable? && collections_editable?(record.collection_druids)
  end

  # The user must be able to edit every collection the item is being added to; existing memberships may be kept.
  # @return [Boolean]
  def add_to_collections?
    collections_editable?(record.collection_druids - Array(record.previous_cocina_object.structural&.isMemberOf))
  end

  # The user must be able to edit the APO the item is being moved to; the current APO may be kept.
  # @return [Boolean]
  def update_apo?
    record.apo_druid == record.previous_cocina_object.administrative.hasAdminPolicy || apo_editable?
  end

  private

  # Unlike for an existing object, an edit permission on the APO's own governing APO does not suffice.
  def apo_editable?
    return new? if record.apo_druid.blank?

    permission_scope.edit_targets.include?(record.apo_druid)
  end

  def collections_editable?(collection_druids)
    Array(collection_druids).all? { |collection_druid| collection_editable?(collection_druid) }
  end

  # Editable when an edit permission targets the collection or its APO.
  def collection_editable?(collection_druid)
    return true if permission_scope.edit_targets.include?(collection_druid)

    allowed_to?(:edit?, Sdr::Repository.find_solr(druid: collection_druid), with: ObjectPolicy)
  rescue Sdr::Repository::NotFoundResponse
    false
  end
end
