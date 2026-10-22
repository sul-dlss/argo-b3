# frozen_string_literal: true

module Admin
  # Renders a permission in an object's permissions table.
  class ObjectPermissionRowComponent < ApplicationComponent
    # @param permission [Permission] the object-scoped permission
    # @return [void]
    def initialize(permission:)
      @permission = permission
      super()
    end

    # @return [Permission]
    attr_reader :permission

    # @return [String] the user-facing permission label
    def permission_label
      permission.permission_type_read_restricted? ? 'Read' : 'Edit'
    end

    # @return [String] an accessible delete button label
    def delete_label
      "Delete #{permission_label} permission for #{permission.workgroup}"
    end
  end
end
