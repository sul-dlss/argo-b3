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

      private

      def sort_key_requires_part_label
        return unless catalog_link_sort_key.present? && catalog_link_part_label.blank?

        errors.add(:catalog_link_sort_key, 'requires catalog_link_part_label to be present')
      end
    end
  end
end
