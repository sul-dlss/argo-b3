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
    release_tags.map { |release_tag| { label: release_tag.to, url: release_tag_url(release_tag) } }
  end

  private

  attr_reader :document, :version_service, :release_tags

  def unreleased?
    release_tags.empty? || undeposited?
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
