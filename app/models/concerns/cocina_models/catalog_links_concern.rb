# frozen_string_literal: true

module CocinaModels
  # Concern for handling catalog links in Cocina models.
  module CatalogLinksConcern
    extend ActiveSupport::Concern

    included do
      has_many :folio_catalog_links, class_name: 'CocinaModels::FolioCatalogLink', allow_destroy: true

      # These attributes apply to the first Folio catalog link.
      attribute :catalog_link_refresh, :boolean, default: false
      attribute :catalog_link_part_label, :string
      attribute :catalog_link_sort_key, :string
      validate :sort_key_requires_part_label

      def find_folio_catalog_link(catalog_record_id:)
        folio_catalog_links.find { |link| link.catalog_record_id == catalog_record_id }
      end

      def catalog_link_refresh? = catalog_link_refresh

      def folio_catalog_links_changed?
        existing_catalog_record_ids = Array(previous_cocina_object.identification&.catalogLinks)
                                      .select { |link| link.catalog == 'folio' }
                                      .map(&:catalogRecordId)

        folio_catalog_links.map(&:catalog_record_id).sort != existing_catalog_record_ids.sort
      end

      # This bubbles up changes to the parent objects.
      def tracked_associations_changed?
        super || folio_catalog_links_changed?
      end

      private

      def sort_key_requires_part_label
        return unless catalog_link_sort_key.present? && catalog_link_part_label.blank?

        errors.add(:catalog_link_sort_key, 'requires catalog_link_part_label to be present')
      end
    end
  end
end
