# frozen_string_literal: true

# Concern for the collection fields used by forms that support selecting collections.
module CollectionFormConcern
  extend ActiveSupport::Concern

  included do
    # Removes the blank value submitted by the multiple select.
    normalizes_array_compact_blank :collection_druids
    # wasSeedPreassemblyWF builds a seed's description from its collection, so registering a seed without one
    # is probably a mistake. Existing seeds are not checked when edited.
    validate :webarchive_seed_in_collection, unless: :persisted?

    attribute :limit_collection_by_apo, :boolean, default: false
  end

  private

  def webarchive_seed_in_collection
    return unless content_type == Cocina::Models::ObjectType.webarchive_seed
    return if collection_druids.any?

    errors.add(:collection_druids, I18n.t('edit.items.fields.collection_druids.validations.webarchive_seed'))
  end
end
