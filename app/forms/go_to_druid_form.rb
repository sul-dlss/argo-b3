# frozen_string_literal: true

# Form for "Go to druid" on dashboard
class GoToDruidForm < ApplicationForm
  attribute :druid, :string

  normalizes :druid, with: lambda { |druid|
    druid = druid&.strip
    druid.present? && !druid.start_with?('druid:') ? "druid:#{druid}" : druid
  }

  validates :druid, druid: true
  validate :druid_exists, if: -> { errors[:druid].empty? }

  private

  def druid_exists
    Sdr::Repository.find_solr(druid:)
  rescue Sdr::Repository::NotFoundResponse
    errors.add(:druid, 'does not exist')
  end
end
