# frozen_string_literal: true

# Form for a collection's release tags, when registering it or changing them.
# Per target, nothing is released, or the collection is released alone or with its member items.
class CollectionReleaseTagsForm < ApplicationForm
  # The release tag "what" values.
  RELEASE_COLLECTION = 'self'
  RELEASE_COLLECTION_AND_MEMBERS = 'collection'

  TARGET_PREFIXES = ReleaseTagsForm::TARGET_PREFIXES

  attribute :searchworks_release, :boolean, default: false
  attribute :searchworks_what, :string, default: RELEASE_COLLECTION_AND_MEMBERS
  attribute :earthworks_release, :boolean, default: false
  attribute :earthworks_what, :string, default: RELEASE_COLLECTION_AND_MEMBERS
  attribute :purl_sitemap_release, :boolean, default: false
  attribute :purl_sitemap_what, :string, default: RELEASE_COLLECTION_AND_MEMBERS

  # @param [Array<Dor::Services::Client::ReleaseTag>] release_tags the collection's tags
  # @return [CollectionReleaseTagsForm] a form with each target released as its latest tag releases it
  def self.from_release_tags(release_tags)
    attributes = TARGET_PREFIXES.each_with_object({}) do |(release_target, prefix), attrs|
      latest_tag = latest_tag(release_tags.select { |tag| tag.to == release_target })
      next unless latest_tag&.release

      attrs[:"#{prefix}_release"] = true
      attrs[:"#{prefix}_what"] = latest_tag.what
    end
    new(attributes)
  end

  # @param [Array<Dor::Services::Client::ReleaseTag>] tags
  # @return [Dor::Services::Client::ReleaseTag, nil] the latest of the tags
  def self.latest_tag(tags)
    tags.max_by(&:date)
  end

  # @param [Symbol] prefix a field prefix from TARGET_PREFIXES
  # @return [Boolean] whether the target is released
  def released?(prefix)
    public_send(:"#{prefix}_release")
  end

  # @param [Symbol] prefix a field prefix from TARGET_PREFIXES
  # @return [String] what the target releases: RELEASE_COLLECTION or RELEASE_COLLECTION_AND_MEMBERS
  def release_what(prefix)
    public_send(:"#{prefix}_what")
  end

  # @param [String] druid
  # @param [String] user_name the sunetid of the user performing the action
  # @raise [Sdr::Repository::Error] if there is an error creating a release tag
  # @return [void]
  def create!(druid:, user_name:)
    save!(druid:, user_name:, release_tags: [])
  end

  # Creates release tags for the targets whose latest tag differs from the choice.
  # @param [String] druid
  # @param [String] user_name the sunetid of the user performing the action
  # @param [Array<Dor::Services::Client::ReleaseTag>] release_tags the collection's tags
  # @raise [Sdr::Repository::Error] if there is an error creating a release tag
  # @return [Array<String>] the release targets that release tags were created for
  def save!(druid:, user_name:, release_tags:)
    TARGET_PREFIXES.filter_map do |release_target, prefix|
      target_tags = release_tags.select { |tag| tag.to == release_target }
      release = released?(prefix)
      what = release_what(prefix)
      next if unchanged?(latest_tag: self.class.latest_tag(target_tags), release:, what:)

      create_release_tags(druid:, user_name:, release_target:, target_tags:, release:, what:)
      release_target
    end
  end

  private

  def create_release_tags(druid:, user_name:, release_target:, target_tags:, release:, what:) # rubocop:disable Metrics/ParameterLists
    now = Time.now.utc
    if release && what == RELEASE_COLLECTION && members_released?(target_tags)
      # A "self" tag leaves members as they are, so withdraw them first; the later tag re-releases the collection.
      withdraw_date = tag_date(target_tags:, date: now - 1.second)
      Sdr::Repository.create_release_tag(druid:, user_name:, release_target:, release: false,
                                         release_what: RELEASE_COLLECTION_AND_MEMBERS, date: withdraw_date)
      now = withdraw_date + 1.second
    end
    Sdr::Repository.create_release_tag(druid:, user_name:, release_target:, release:,
                                       release_what: release ? what : RELEASE_COLLECTION_AND_MEMBERS,
                                       date: tag_date(target_tags:, date: now))
  end

  # DSA orders tags by date in whole seconds, so a new tag must be at least a second after the latest.
  def tag_date(target_tags:, date:)
    latest_tag = self.class.latest_tag(target_tags)
    return date unless latest_tag

    [date, latest_tag.date.to_time.utc + 1.second].max
  end

  # Not releasing matches any "do not release" tag (or none), so saving unchanged never withdraws the members.
  def unchanged?(latest_tag:, release:, what:)
    return !latest_tag&.release unless release

    latest_tag&.release && latest_tag.what == what
  end

  # Member items follow only the collection's latest tag that covers them.
  def members_released?(target_tags)
    self.class.latest_tag(target_tags.select { |tag| tag.what == RELEASE_COLLECTION_AND_MEMBERS })&.release || false
  end
end
