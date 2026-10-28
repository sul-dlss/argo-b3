# frozen_string_literal: true

# Presenter for the purge (first version) or discard draft (later version) button of an object.
class DiscardOrPurgePresenter
  # @param cocina_version [Integer] the version of the cocina object
  # @param version_service [Sdr::VersionService] the object's version service
  def initialize(cocina_version:, version_service:)
    @cocina_version = cocina_version
    @version_service = version_service
  end

  # @return [Boolean] true if the button purges the object, false if it discards the draft
  def purge?
    cocina_version == 1
  end

  # Lazy, since checking requires DSA requests.
  # @return [Boolean] true if the object can be purged or its draft discarded
  def available?
    return @available if defined?(@available)

    @available = if purge?
                   Sdr::PurgeService.purgeable?(druid:, version: cocina_version)
                 else
                   Sdr::DiscardDraftService.discardable?(version: cocina_version, version_service:)
                 end
  end

  def label
    purge? ? I18n.t('edit.items.edit.buttons.purge') : I18n.t('edit.items.edit.buttons.discard_draft')
  end

  def confirm
    purge? ? I18n.t('edit.items.edit.buttons.purge_confirm') : I18n.t('edit.items.edit.buttons.discard_draft_confirm')
  end

  def path
    url_helpers = Rails.application.routes.url_helpers
    purge? ? url_helpers.purge_object_path(druid) : url_helpers.discard_draft_object_path(druid)
  end

  private

  attr_reader :cocina_version, :version_service

  def druid
    version_service.druid
  end
end
