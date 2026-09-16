# frozen_string_literal: true

module Permissions
  # Resolves permission targets for the workgroups currently in effect.
  # Only memoized within this instance; permission changes need no cache invalidation.
  class UserScope
    # @param groups [Array<String>] workgroups currently in effect for authorization
    def initialize(groups:)
      @groups = groups
    end

    # @return [Boolean] true when an effective workgroup has administrator permission
    def admin?
      permission_type?('admin')
    end

    # @return [Boolean] true when an effective workgroup may read objects that are not restricted
    def read_unrestricted?
      permission_type?('read_unrestricted')
    end

    # @return [Array<String>] unique target druids granted edit permission
    def edit_targets
      targets_for('edit')
    end

    # @return [Array<String>] unique target druids granted restricted-read permission
    def restricted_targets
      targets_for('read_restricted')
    end

    # @return [Array<String>] unique target druids readable by the effective workgroups (note: edit implies read)
    def allowed_targets
      (edit_targets + restricted_targets).uniq.sort
    end

    # Returns restricted targets across every workgroup, not only the effective workgroups.
    # Unrestricted readers must be prevented from reading objects matching these targets.
    # @return [Array<String>] sorted, unique target druids with a restricted-read permission
    def all_restricted_targets
      @all_restricted_targets ||= Permission.permission_type_read_restricted.distinct.pluck(:target_druid).compact.sort
    end

    private

    def permissions
      @permissions ||= Permission.where(workgroup: @groups).pluck(:permission_type, :target_druid)
    end

    def permission_type?(type)
      permissions.any? { |permission_type, _target_druid| permission_type == type }
    end

    def targets_for(type)
      permissions.filter_map { |permission_type, target| target if permission_type == type }.uniq.sort
    end
  end
end
