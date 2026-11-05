# frozen_string_literal: true

# Presenter for versions information about an object.
class VersionsPresenter
  Version = Struct.new('Version', :version, :user_version, :description, :opened_at, :accessioned_at, :purl_url,
                       :cocina, :withdrawn, :withdrawable, :restorable) do
    def cocina?
      cocina
    end

    def withdrawn?
      withdrawn
    end

    def withdrawable?
      withdrawable
    end

    def restorable?
      restorable
    end
  end

  # @param druid [String]
  # @param version_inventory [Array<Dor::Services::Client::Version::Version>]
  # @param milestones [Array<Hash>]
  # @param user_version_inventory [Array<Dor::Services::Client::UserVersion::Version>]
  def initialize(druid:, version_inventory:, milestones:, user_version_inventory: [])
    @druid = druid
    @version_inventory = version_inventory
    @milestones = milestones.map(&:with_indifferent_access)
    @user_version_inventory = user_version_inventory
  end

  def versions
    @versions ||= version_inventory.sort_by(&:version).reverse.map do |version|
      Version.new(version: version.version,
                  description: version.message,
                  opened_at: opened_at(version: version.version),
                  accessioned_at: milestone_at(version: version.version, milestone: 'accessioned'),
                  cocina: version.cocina?,
                  **user_version_attrs(user_version_for(version: version.version)))
    end
  end

  private

  attr_reader :druid, :version_inventory, :milestones, :user_version_inventory

  def opened_at(version:)
    milestone_at(version:, milestone: 'opened') || milestone_at(version:, milestone: 'registered')
  end

  def milestone_at(version:, milestone:)
    milestones.find { |m| m['version'].to_i == version.to_i && m['milestone'] == milestone }&.dig('at')
  end

  def user_version_attrs(user_version)
    {
      user_version: user_version&.userVersion,
      purl_url: purl_url_for(user_version),
      withdrawn: withdrawn?(user_version),
      withdrawable: user_version&.withdrawable? || false,
      restorable: user_version&.restorable? || false
    }
  end

  # DSA reports a permanently withdrawn user version as not withdrawn, but also as neither withdrawable nor the head.
  def withdrawn?(user_version)
    return false unless user_version

    user_version.withdrawn || !(user_version.withdrawable? || user_version.head?)
  end

  def user_version_for(version:)
    user_version_inventory.find { |user_version| user_version.version == version }
  end

  # Withdrawn user versions are not on PURL. The latest user version's PURL omits the version.
  def purl_url_for(user_version)
    return if !user_version || withdrawn?(user_version)

    purl_url = Cocina::Models::Mapping::Purl.for(druid:)
    user_version.head? ? purl_url : "#{purl_url}/version/#{user_version.userVersion}"
  end
end
