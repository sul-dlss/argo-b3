# frozen_string_literal: true

# Base class for application policies
class ApplicationPolicy < ActionPolicy::Base
  class_attribute :admin_workgroups
  pre_check :allow_admins

  def allow_admins
    allow! if admin?
  end

  def admin?
    current_groups.intersect?(admin_workgroups)
  end

  def current_groups
    Current.effective_groups || user.groups
  end

  private

  def admin_workgroups
    # This is the simplest possible form of caching on the assumption
    # that admin groups will rarely (if ever) be changing.
    # Changing would require a restart of the app.
    self.class.admin_workgroups ||= Permission.permission_type_admin.pluck(:workgroup)
  end
end
