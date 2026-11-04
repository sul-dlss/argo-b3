# frozen_string_literal: true

# Form for changing the release tags of an existing item.
# Release tags cannot be deleted, so a target with an item tag can no longer follow the collection.
class ItemReleaseTagsForm < ApplicationForm
  FOLLOW_COLLECTION = ReleaseTagsForm::RELEASE_TO_COLLECTION
  RELEASE = ReleaseTagsForm::RELEASE_TO_TARGETS
  NO_RELEASE = ReleaseTagsForm::NO_RELEASE

  TARGET_FIELDS = {
    'Searchworks' => :searchworks_target,
    'Earthworks' => :earthworks_target,
    'PURL sitemap' => :purl_sitemap_target
  }.freeze

  attribute :searchworks_target, :string, default: FOLLOW_COLLECTION
  attribute :earthworks_target, :string, default: FOLLOW_COLLECTION
  attribute :purl_sitemap_target, :string, default: FOLLOW_COLLECTION

  # @param [Array<Dor::Services::Client::ReleaseTag>] release_tags the item's own tags (not its collections')
  # @return [ItemReleaseTagsForm] a form with each tagged target set to its latest tag
  def self.from_release_tags(release_tags)
    new(tagged_choices(release_tags))
  end

  # @param [Array<Dor::Services::Client::ReleaseTag>] release_tags the item's own tags (not its collections')
  # @return [Hash{Symbol => String}] field => RELEASE or NO_RELEASE, for targets with an item tag
  def self.tagged_choices(release_tags)
    release_tags.group_by(&:to).filter_map do |release_target, tags|
      field = TARGET_FIELDS[release_target]
      next unless field

      [field, tags.max_by(&:date).release ? RELEASE : NO_RELEASE]
    end.to_h
  end

  # @param [String] druid
  # @param [String] user_name the sunetid of the user performing the action
  # @param [Array<Dor::Services::Client::ReleaseTag>] release_tags the item's own tags (not its collections')
  # @raise [Sdr::Repository::Error] if there is an error creating a release tag
  # @return [Array<String>] the release targets that a release tag was created for
  def save!(druid:, user_name:, release_tags:)
    current_choices = self.class.tagged_choices(release_tags)
    TARGET_FIELDS.filter_map do |release_target, field|
      choice = public_send(field)
      # Following the collection (or an unknown choice) creates no tag.
      next unless [RELEASE, NO_RELEASE].include?(choice) && choice != current_choices[field]

      Sdr::Repository.create_release_tag(druid:, user_name:, release_target:, release: choice == RELEASE)
      release_target
    end
  end
end
