# frozen_string_literal: true

module Permissions
  # Resolves permission targets for the workgroups currently in effect.
  # Only memoized within this instance; permission changes need no cache invalidation.
  class UserScope
    def initialize(groups:)
      @groups = groups
    end

    def admin?
      permission_type?('admin')
    end

    def read_unrestricted?
      permission_type?('read_unrestricted')
    end

    def edit_targets
      targets_for('edit')
    end

    def restricted_targets
      targets_for('read_restricted')
    end

    def allowed_targets
      (edit_targets + restricted_targets).uniq.sort
    end

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
