# frozen_string_literal: true

# Form for release tags.
class ReleaseTagsForm < ApplicationForm
  RELEASE_TO_COLLECTION = 'release_to_collection'
  RELEASE_TO_TARGETS = 'release_to_targets'
  NO_RELEASE = 'no_release'

  attribute :release_choice, :string, default: NO_RELEASE
  validates :release_choice, presence: true,
                             inclusion: { in: [RELEASE_TO_COLLECTION, RELEASE_TO_TARGETS, NO_RELEASE] }

  attribute :searchworks_target, :boolean, default: false
  attribute :earthworks_target, :boolean, default: false
  attribute :purl_sitemap_target, :boolean, default: false

  validate :at_least_one_target, if: -> { release_choice == RELEASE_TO_TARGETS }

  # @param [String] druid
  # @param [String] user_name the sunetid of the user performing the action
  # @raise [Sdr::Repository::Error] if there is an error creating the release tag
  # @raise [ActiveModel::ValidationError] if the model is invalid
  def create!(druid:, user_name:)
    validate!
    return if release_choice == RELEASE_TO_COLLECTION

    if release_choice == NO_RELEASE
      return Sdr::Repository.create_release_tag(druid:, user_name:, release_target: nil, release: false)
    end

    create_release_tag(druid:, user_name:, create: searchworks_target, release_target: 'Searchworks')
    create_release_tag(druid:, user_name:, create: earthworks_target, release_target: 'Earthworks')
    create_release_tag(druid:, user_name:, create: purl_sitemap_target, release_target: 'PURL sitemap')
  end

  private

  def at_least_one_target
    return if searchworks_target || earthworks_target || purl_sitemap_target

    errors.add(:release_targets, 'At least one target must be selected')
  end

  def create_release_tag(druid:, user_name:, create:, release_target:)
    return unless create

    Sdr::Repository.create_release_tag(druid:, user_name:, release_target:, release: true)
  end
end
