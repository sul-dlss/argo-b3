# frozen_string_literal: true

module Admin
  # Renders a read restricted or edit permission held by a workgroup in an APO or collection's permissions table.
  class ObjectPermissionRowComponent < ApplicationComponent
    def initialize(permission:)
      @permission = permission
      super()
    end

    attr_reader :permission

    def permission_label
      t("admin.object_permissions.fields.permission_type.#{permission.permission_type}")
    end

    def delete_label
      t('admin.object_permissions.buttons.delete', permission: permission_label, workgroup: permission.workgroup)
    end

    def delete_path
      helpers.admin_object_permission_path(permission.target_druid, permission)
    end
  end
end
