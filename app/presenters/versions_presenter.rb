# frozen_string_literal: true

# Presenter for versions information about an object.
class VersionsPresenter
  Version = Struct.new('Version', :version, :user_version, :description, :opened_at, :submitted_at, :accessioned_at)

  # @param version_inventory [Array<Dor::Services::Client::Version::Version>]
  # @param milestones [Array<Hash>]
  # @param user_version_inventory [Array<Dor::Services::Client::UserVersion::Version>]
  def initialize(version_inventory:, milestones:, user_version_inventory: [])
    @version_inventory = version_inventory
    @milestones = milestones.map(&:with_indifferent_access)
    @user_version_inventory = user_version_inventory
  end

  def versions
    @versions ||= version_inventory.sort_by(&:version).reverse.map do |version|
      Version.new(version: version.version,
                  user_version: user_version_for(version: version.version),
                  description: version.message,
                  opened_at: opened_at(version: version.version),
                  submitted_at: milestone_at(version: version.version, milestone: 'submitted'),
                  accessioned_at: milestone_at(version: version.version, milestone: 'accessioned'))
    end
  end

  private

  attr_reader :version_inventory, :milestones, :user_version_inventory

  def opened_at(version:)
    milestone_at(version:, milestone: 'opened') || milestone_at(version:, milestone: 'registered')
  end

  def milestone_at(version:, milestone:)
    milestones.find { |m| m['version'].to_i == version.to_i && m['milestone'] == milestone }&.dig('at')
  end

  def user_version_for(version:)
    user_version_inventory.find { |user_version| user_version.version == version }&.userVersion
  end
end
