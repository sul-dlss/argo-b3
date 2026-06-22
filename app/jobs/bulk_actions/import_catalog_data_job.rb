# frozen_string_literal: true

require 'csv'

module BulkActions
  # Job to import catalog data (FOLIO Instance HRIDs, barcodes, and serials metadata)
  # from a CSV file and update objects accordingly.
  class ImportCatalogDataJob < ClosingCsvJob
    FOLIO_HRID_COLUMN = 'folio_instance_hrid'

    # Imports catalog data for a single CSV row
    class JobItem < BaseCsvJobItem
      def perform # rubocop:disable Metrics/AbcSize
        return unless check_update_ability?
        return unless check_object_type?(allow_admin_policy: false)
        return unless check_barcode_for_collection?

        cocina_model.barcode = new_barcode if cocina_object.dro?
        replace_folio_catalog_links

        unless cocina_model.valid?
          return failure!(message: "Invalid catalog data: #{cocina_model.errors.full_messages.join(', ')}")
        end

        return success!(message: 'No changes to catalog data') unless cocina_model.changed?

        open_new_version_if_needed!(description: description_msg)

        log_catalog_record_id_update
        log_barcode_update

        cocina_model.save!(user_name: user_id, description: description_msg)

        close_version_if_needed!
        success!(message: 'Catalog data updated')
      end

      private

      def description_msg
        'Updated FOLIO HRID, barcode, or serials metadata'
      end

      def replace_folio_catalog_links # rubocop:disable Metrics/AbcSize
        cocina_model.catalog_link_refresh = new_refresh?
        cocina_model.catalog_link_part_label = new_part_label
        cocina_model.catalog_link_sort_key = new_sort_key
        cocina_model.folio_catalog_links.clear
        new_folio_catalog_record_ids.map do |catalog_record_id|
          cocina_model.folio_catalog_links.new(catalog_record_id:)
        end
      end

      def check_barcode_for_collection?
        return true unless new_barcode.present? && cocina_object.collection?

        failure!(message: 'Barcodes can only be added to DROs')
        false
      end

      def new_folio_catalog_record_ids
        hrid_column_indices = row.headers.each_index.select { |i| row.headers[i] == FOLIO_HRID_COLUMN }
        row.fields(*hrid_column_indices).compact.map(&:strip).reject(&:empty?)
      end

      def new_refresh?
        row['refresh']&.downcase != 'false'
      end

      def new_part_label
        row['part_label']&.strip.presence
      end

      def new_sort_key
        row['sort_key']&.strip.presence
      end

      def new_barcode
        row['barcode']&.strip.presence
      end

      def log_catalog_record_id_update
        return unless cocina_model.folio_catalog_links_changed?

        if new_folio_catalog_record_ids.present?
          log("Adding FOLIO Instance HRIDs: #{new_folio_catalog_record_ids.join(', ')}")
        else
          log('Removing FOLIO Instance HRIDs')
        end
      end

      def log_barcode_update
        return unless cocina_object.dro?
        return unless cocina_model.barcode_changed?

        if new_barcode.present?
          log("Adding barcode: #{new_barcode}")
        else
          log('Removing barcode')
        end
      end
    end
  end
end
