# frozen_string_literal: true

module CocinaModels
  # Model for a Folio catalog link (catalog: 'folio').
  class FolioCatalogLink < CatalogLinkBase
    def catalog = 'folio'

    attribute :part_label, :string
    attribute :sort_key, :string

    validates :catalog_record_id, format: { with: /\A(a\d+|L\d+|in\d+)\z/ }, allow_blank: true
    validate :sort_key_requires_part_label

    private

    def sort_key_requires_part_label
      errors.add(:sort_key, 'requires part_label to be present') if sort_key.present? && part_label.blank?
    end
  end
end
