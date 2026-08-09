# frozen_string_literal: true

# Model for a permission record. A permission record is a single permission
# for a workgroup with an optional target APO or collection.
#
# Note that there is a default admin permission for sdr:argo_administrators workgroup.
class Permission < ApplicationRecord
  validates :workgroup, presence: true

  enum :permission_type, {
    # A workgroup with an admin permission can do anything.
    admin: 'admin',
    # A workgroup with read_restricted can read:
    # * the target collection or APO
    # * any object that is a member of the target collection
    # * any object that has the target APO
    read_restricted: 'read_restricted',
    # A workgroup with read_unrestricted can read any object that is not restricted.
    read_unrestricted: 'read_unrestricted',
    # A workgroup with edit can create a new object in which:
    # * the object's collection is the target collection
    # * the object's APO is the target APO
    # A workgroup with edit can edit:
    # * the target collection or APO
    # * any object that is a member of the target collection
    # * any object that has the target APO
    edit: 'edit'
  }, prefix: true
  validates :permission_type, presence: true

  validates :target_druid, druid: true, allow_nil: true
  validate :target_druid_present_for_restricted_permission_types

  private

  def target_druid_present_for_restricted_permission_types
    return if target_druid.present?
    return unless permission_type_read_restricted? || permission_type_edit?

    errors.add(:target_druid, "can't be blank for #{permission_type} permission type")
  end
end
