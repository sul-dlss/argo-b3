# frozen_string_literal: true

module Admin
  # Renders a workgroup permission and its target object in the additional permissions table.
  class WorkgroupPermissionRowComponent < ApplicationComponent
    def initialize(permission:, object_doc:)
      @permission = permission
      @object_doc = object_doc
      super()
    end

    attr_reader :permission, :object_doc

    def title_link
      return DruidSupport.bare_druid_from(permission.target_druid) unless object_doc

      helpers.link_to_object(object_doc.title.presence || object_doc.bare_druid, object_doc.druid)
    end

    def permission_label
      permission.permission_type.humanize
    end

    def delete_label
      t('admin.workgroup_permissions.buttons.delete', target: permission.target_druid || permission_label)
    end
  end
end
