# frozen_string_literal: true

# Presenter for the release status and release target links of an object.
class ObjectReleasedPresenter
  include LinkHelper

  def initialize(document:, version_service:, release_tags:)
    @document = document
    @version_service = version_service
    @release_tags = release_tags
  end

  def heading
    return I18n.t('show.released_to.unreleased.heading') if unreleased?

    I18n.t('show.released_to.released.heading')
  end

  def release_tag_links
    released_release_tags.map do |release_tag|
      { label: Constants::RELEASE_TARGETS.to_h.invert.fetch(release_tag.to, release_tag.to), url: release_tag_url(release_tag) }
    end
  end

  private

  attr_reader :document, :version_service, :release_tags

  def released_release_tags
    # A release tag can have release=false indicating that the object should not be released to that target
    # (even if the collection is released to that target).
    release_tags.select(&:release)
  end

  def unreleased?
    released_release_tags.empty? || undeposited?
  end

  def undeposited?
    version_service.version == 1 && (version_service.open? || version_service.accessioning?)
  end

  def release_tag_url(release_tag)
    case release_tag.to
    when 'PURL sitemap'
      Cocina::Models::Mapping::Purl.for(druid: document.druid)
    when 'Searchworks'
      searchworks_url(document.druid, catalog_record_id)
    when 'Earthworks'
      earthworks_url(document.druid)
    end
  end

  def catalog_record_id
    Array(document.catalog_record_id).first
  end
end
