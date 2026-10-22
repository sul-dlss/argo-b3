# frozen_string_literal: true

module Admin
  # Adds a workgroup permission to an APO or collection.
  class ObjectPermissionForm < ApplicationForm
    attribute :workgroup, :string
    attribute :permission_type, :string

    normalizes_whitespace :workgroup

    validates :workgroup, presence: true
    validates :permission_type, inclusion: { in: %w[read_restricted edit] }

    # @param target_druid [String] the authorized object's druid
    # @return [Boolean] whether the permission was saved
    def save(target_druid:)
      return false unless valid?

      permission = Permission.new(workgroup:, permission_type:, target_druid:)
      # A savepoint keeps a duplicate-key failure from aborting an enclosing transaction.
      return true if Permission.transaction(requires_new: true) { permission.save }

      errors.merge!(permission.errors)
      false
    rescue ActiveRecord::RecordNotUnique
      errors.add(:workgroup, I18n.t('admin.object_permissions.errors.duplicate_permission'))
      false
    end
  end
end
