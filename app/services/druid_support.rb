# frozen_string_literal: true

# Methods for working with druids
class DruidSupport
  def self.bare_druid_from(druid)
    return if druid.nil?

    druid.delete_prefix('druid:')
  end
end
