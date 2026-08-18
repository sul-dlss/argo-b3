# frozen_string_literal: true

# Base class for application policies
class ApplicationPolicy < ActionPolicy::Base
  pre_check :allow_admins

  def allow_admins
    allow! if admin?
  end

  def admin?
    user.groups.intersect?(admin_workgroups)
  end

  private

  def admin_workgroups
    # This is the simplest possible form of caching on the assumption
    # that admin groups will rarely (if ever) be changing.
    # Changing would require a restart of the app.
    @@admin_workgroups ||= Permission.permission_type_admin.pluck(:workgroup) # rubocop:disable Style/ClassVars
  end
end
