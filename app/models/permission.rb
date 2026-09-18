# frozen_string_literal: true

# Model for a permission record. A permission record is a single permission
# for a workgroup with an optional target APO or collection.
#
# Note that there is a default admin permission for sdr:argo_administrators workgroup.
class Permission < ApplicationRecord
  CREATED_EVENT_TYPE = 'argo_permission_created'
  DELETED_EVENT_TYPE = 'argo_permission_deleted'

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

  after_create_commit :create_created_event
  after_destroy_commit :create_deleted_event

  private

  def target_druid_present_for_restricted_permission_types
    return if target_druid.present?
    return unless permission_type_read_restricted? || permission_type_edit?

    errors.add(:target_druid, "can't be blank for #{permission_type} permission type")
  end

  def create_created_event
    create_event(type: CREATED_EVENT_TYPE)
  end

  def create_deleted_event
    create_event(type: DELETED_EVENT_TYPE)
  end

  # Record the permission change as an event on the target object in SDR.
  # Events are only created when there is a target object and a current user,
  # e.g., not for permissions created from the console, seeds, or a data migration.
  # A failure to create the event must not prevent the permission change itself.
  # @param [String] type the type of the event
  def create_event(type:)
    return if target_druid.blank? || Current.user.blank?

    Sdr::Event.create(druid: target_druid, type:,
                      data: { who: Current.user.sunetid,
                              host: Sdr::Event.host,
                              permission_type: })
  rescue StandardError => e
    Honeybadger.notify(e, context: { permission_id: id, target_druid:, event_type: type })
  end
end
