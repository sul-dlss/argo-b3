# frozen_string_literal: true

# Methods for working with druids
class DruidSupport
  def self.bare_druid_from(druid)
    return if druid.nil?

    druid.delete_prefix('druid:')
  end

  def self.prefixed_druid_from(druid)
    return if druid.nil?

    druid.start_with?('druid:') ? druid : "druid:#{druid}"
  end

  # @param druid_list [String] A string containing druids separated by whitespace
  # @return [Array<String>] An array of prefixed druids
  def self.parse_list(druid_list)
    return [] if druid_list.blank?

    druid_list.split(/\s+/).map(&:strip).map { |druid| prefixed_druid_from(druid) }
  end
end
