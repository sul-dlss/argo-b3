# frozen_string_literal: true

module BulkActions
  # Job to create or delete read restricted and edit permissions for collections / APOs from a CSV.
  class ImportReadRestrictedAndEditPermissionsJob < BaseCsvJob
    PERMISSION_TYPES = %w[read_restricted edit].freeze

    # Create or delete permissions for a single CSV row.
    class JobItem < BaseCsvJobItem
      def perform
        return unless check_druid?
        return unless check_workgroup?
        return unless check_permission_type?

        permission_type.blank? ? destroy_permissions : create_permission
      end

      private

      def workgroup
        @workgroup ||= row['workgroup']&.strip
      end

      def permission_type
        @permission_type ||= row['permission_type']&.strip&.downcase
      end

      # For example, "read restricted" for a permission type of "read_restricted".
      def permission_label
        permission_type.humanize.downcase
      end

      def check_druid?
        return true if druid.present?

        failure!(message: 'Missing required value for "druid"')
        false
      end

      def check_workgroup?
        return true if workgroup.present?

        failure!(message: 'Missing required value for "workgroup"')
        false
      end

      def check_permission_type?
        return true if permission_type.blank? || permission_type.in?(PERMISSION_TYPES)

        failure!(message: "\"#{row['permission_type']}\" is not a valid value for \"permission_type\"")
        false
      end

      def create_permission
        # Only collections and APOs can be the target of a read restricted or edit permission.
        return unless check_object_type?(allow_dro: false)

        if Permission.exists?(permission_type:, workgroup:, target_druid: druid)
          return failure!(message: "#{permission_label.upcase_first} permission already exists for #{workgroup}")
        end

        Permission.create!(permission_type:, workgroup:, target_druid: druid)
        success!(message: "Created #{permission_label} permission for #{workgroup}")
      end

      # Note that the object type is not checked when deleting so that permissions can be removed
      # even when the object no longer exists or is not a collection or APO.
      def destroy_permissions
        destroyed = Permission.where(permission_type: PERMISSION_TYPES, workgroup:, target_druid: druid).destroy_all
        if destroyed.empty?
          return failure!(message: "No read restricted or edit permissions to delete for #{workgroup}")
        end

        success!(message: "Deleted #{destroyed.size} #{'permission'.pluralize(destroyed.size)} for #{workgroup}")
      end
    end

    # Current.user is not otherwise set in a job, but is needed so that permission changes
    # are recorded as events in SDR.
    def perform_bulk_action
      Current.set(user:) { super }
    end
  end
end
