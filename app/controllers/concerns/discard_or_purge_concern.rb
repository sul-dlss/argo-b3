# frozen_string_literal: true

# Concern for edit forms that render the discard draft or purge button (Item::DiscardOrPurgeButtonComponent).
module DiscardOrPurgeConcern
  extend ActiveSupport::Concern

  private

  # @return [Symbol, nil] :purge, :discard_draft, or nil if neither is possible
  def discard_or_purge_action(cocina_object:, version_service:)
    return :purge if Sdr::PurgeService.purgeable?(druid: cocina_object.externalIdentifier,
                                                  version: cocina_object.version)

    :discard_draft if Sdr::DiscardDraftService.discardable?(cocina_object:, version_service:)
  end
end
