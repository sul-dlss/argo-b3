# frozen_string_literal: true

module Show
  # Renders the workgroups with a read or edit permission targeting an APO or collection.
  class PermissionsTableComponent < ApplicationComponent
    # @param permission_types_by_workgroup [Hash{String => String}] permission type by workgroup, sorted by workgroup
    def initialize(permission_types_by_workgroup:)
      @permission_types_by_workgroup = permission_types_by_workgroup
      super()
    end

    # @return [Array<Array(String, String)>] workgroup and permission label pairs, sorted by workgroup
    def rows
      @permission_types_by_workgroup.map do |workgroup, permission_type|
        [workgroup, Permission.permission_type_label(permission_type)]
      end
    end
  end
end
