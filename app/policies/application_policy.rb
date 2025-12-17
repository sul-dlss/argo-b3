# frozen_string_literal: true

# Base class for application policies
class ApplicationPolicy < ActionPolicy::Base
  ADMIN_GROUP = 'sdr:administrator'

  pre_check :allow_admins

  def allow_admins
    allow! if admin?
  end

  private

  def admin?
    user.groups.include?(ADMIN_GROUP)
  end
end
