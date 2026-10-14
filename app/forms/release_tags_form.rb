# frozen_string_literal: true

# Form for release tags.
class ReleaseTagsForm < ApplicationForm
  RELEASE_TO_COLLECTION = 'release_to_collection'
  RELEASE_TO_TARGETS = 'release_to_targets'
  NO_RELEASE = 'no_release'

  attribute :searchworks_target, :string, default: RELEASE_TO_COLLECTION
  attribute :earthworks_target, :string, default: RELEASE_TO_COLLECTION
  attribute :purl_sitemap_target, :string, default: RELEASE_TO_COLLECTION

  # @param [String] druid
  # @param [String] user_name the sunetid of the user performing the action
  # @raise [Sdr::Repository::Error] if there is an error creating the release tag
  def create!(druid:, user_name:)
    create_release_tag(druid:, user_name:, create: searchworks_target, release_target: 'Searchworks')
    create_release_tag(druid:, user_name:, create: earthworks_target, release_target: 'Earthworks')
    create_release_tag(druid:, user_name:, create: purl_sitemap_target, release_target: 'PURL sitemap')
  end

  private

  # "create" is one of the three choices for each target, i.e. release, don't release, follow collection
  def create_release_tag(druid:, user_name:, create:, release_target:)
    return if create == RELEASE_TO_COLLECTION # follow collection settings, no release tag needed

    # the release tag will be true or false, depending on which option the user choose for this target in the drop down
    Sdr::Repository.create_release_tag(druid:, user_name:, release_target:, release: create == RELEASE_TO_TARGETS)
  end
end
