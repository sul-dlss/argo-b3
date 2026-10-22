# frozen_string_literal: true

# Form for the release tags of a new collection. Unlike ReleaseTagsForm (for items), there is no collection
# to follow, and a release may include the collection's member items.
class CollectionReleaseTagsForm < ApplicationForm
  NO_RELEASE = 'no_release'
  # The values for releases are the release tag "what" values.
  RELEASE_COLLECTION = 'self'
  RELEASE_COLLECTION_AND_MEMBERS = 'collection'

  attribute :searchworks_target, :string, default: NO_RELEASE
  attribute :earthworks_target, :string, default: NO_RELEASE
  attribute :purl_sitemap_target, :string, default: NO_RELEASE

  # @param [String] druid
  # @param [String] user_name the sunetid of the user performing the action
  # @raise [Sdr::Repository::Error] if there is an error creating the release tag
  # @return [void]
  def create!(druid:, user_name:)
    create_release_tag(druid:, user_name:, release_what: searchworks_target, release_target: 'Searchworks')
    create_release_tag(druid:, user_name:, release_what: earthworks_target, release_target: 'Earthworks')
    create_release_tag(druid:, user_name:, release_what: purl_sitemap_target, release_target: 'PURL sitemap')
  end

  private

  # A new collection has no release tags, so not releasing to a target needs no tag.
  # @param [String] druid
  # @param [String] user_name
  # @param [String] release_what what to release (a release tag "what" value) or NO_RELEASE
  # @param [String] release_target
  # @return [void]
  def create_release_tag(druid:, user_name:, release_what:, release_target:)
    return if release_what == NO_RELEASE

    Sdr::Repository.create_release_tag(druid:, user_name:, release_target:, release: true, release_what:)
  end
end
