# frozen_string_literal: true

# Presenter for the draft actions of an object: the purge (first version) or discard draft (later version) button.
class DraftActionsPresenter
  # @param cocina_version [Integer] the version of the cocina object
  # @param version_service [Sdr::VersionService] the object's version service
  # @param purge_label [String] the label of the purge button, for contexts that need something more specific
  def initialize(cocina_version:, version_service:, purge_label: I18n.t('edit.items.edit.buttons.purge'))
    @cocina_version = cocina_version
    @version_service = version_service
    @purge_label = purge_label
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
    purge? ? purge_label : I18n.t('edit.items.edit.buttons.discard_draft')
  end

  def confirm
    purge? ? I18n.t('edit.items.edit.buttons.purge_confirm') : I18n.t('edit.items.edit.buttons.discard_draft_confirm')
  end

  def path
    url_helpers = Rails.application.routes.url_helpers
    purge? ? url_helpers.purge_object_path(druid) : url_helpers.discard_draft_object_path(druid)
  end

  private

  attr_reader :cocina_version, :version_service, :purge_label

  def druid
    version_service.druid
  end
end
