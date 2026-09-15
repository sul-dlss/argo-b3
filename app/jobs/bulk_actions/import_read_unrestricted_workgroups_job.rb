# frozen_string_literal: true

module BulkActions
  # Job to create or delete read unrestricted permissions for workgroups from a CSV.
  class ImportReadUnrestrictedWorkgroupsJob < BaseCsvJob
    TRUE_VALUE = 'true'
    FALSE_VALUE = 'false'

    # Create or delete the read unrestricted permission for a single CSV row.
    class JobItem < BaseCsvJobItem
      def perform
        return unless check_workgroup?
        return unless check_read_unrestricted?

        read_unrestricted? ? create_permission : destroy_permission
      end

      private

      def workgroup
        @workgroup ||= row['workgroup']&.strip
      end

      def read_unrestricted_value
        @read_unrestricted_value ||= row['read_unrestricted']&.strip&.downcase
      end

      def read_unrestricted?
        read_unrestricted_value == TRUE_VALUE
      end

      def check_workgroup?
        return true if workgroup.present?

        failure!(message: 'Missing required value for "workgroup"')
        false
      end

      def check_read_unrestricted?
        return true if read_unrestricted_value.in?([TRUE_VALUE, FALSE_VALUE])

        failure!(message: "\"#{row['read_unrestricted']}\" is not a valid value for \"read_unrestricted\"")
        false
      end

      def create_permission
        return failure!(message: "Read unrestricted permission already exists for #{workgroup}") if existing_permission

        Permission.create!(workgroup:, permission_type: :read_unrestricted)
        success!(message: "Created read unrestricted permission for #{workgroup}")
      end

      def destroy_permission
        permission = existing_permission
        return failure!(message: "No read unrestricted permission to delete for #{workgroup}") unless permission

        permission.destroy!
        success!(message: "Deleted read unrestricted permission for #{workgroup}")
      end

      def existing_permission
        Permission.permission_type_read_unrestricted.find_by(workgroup:)
      end
    end

    private

    # There is no druid column in the CSV for this bulk action.
    def check_druid_column?
      true
    end
  end
end
