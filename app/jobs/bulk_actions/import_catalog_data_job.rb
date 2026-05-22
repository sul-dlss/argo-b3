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

        if new_barcode.present?
          return failure!(message: 'Barcodes can only be added to DROs') unless cocina_object.dro?

          cocina_model.barcode = new_barcode
        end

        replace_folio_catalog_links

        unless cocina_model.valid?
          return failure!(message: "Invalid catalog data: #{cocina_model.errors.full_messages.join(', ')}")
        end

        debugger
        return success!(message: 'No changes to catalog data') unless cocina_model.changed?

        open_new_version_if_needed!(description: description_msg)

        log_catalog_record_id_update
        log_barcode_update

        # replace_folio_catalog_links
        # folio_catalog_links association changes do not trigger ActiveModel::Dirty on the parent model.
        # cocina_model.source_id_will_change! unless cocina_model.changed?
        cocina_model.save!(user_name: user_id, description: description_msg)

        close_version_if_needed!
        success!(message: 'Catalog data updated')
      end

      private

      def description_msg
        'Updated FOLIO HRID, barcode, or serials metadata'
      end

      def replace_folio_catalog_links
        cocina_model.folio_catalog_links.clear
        new_folio_instance_hrids.each_with_index do |hrid, index|
          cocina_model.folio_catalog_links.new(
            catalog_record_id: hrid,
            refresh: index.zero? && new_refresh?,
            part_label: new_part_label.presence,
            sort_key: new_sort_key.presence
          )
        end
      end

      def unchanged?
        existing_folio_hrids == new_folio_instance_hrids &&
          existing_refresh == new_refresh? &&
          existing_part_label == new_part_label &&
          existing_sort_key == new_sort_key &&
          existing_barcode == new_barcode.to_s
      end

      # Existing values from the cocina object

      def existing_folio_links
        @existing_folio_links ||= (cocina_object.identification&.catalogLinks || []).select do |link|
          link.catalog == 'folio'
        end
      end

      def existing_folio_hrids
        existing_folio_links.map(&:catalogRecordId)
      end

      def existing_refresh
        existing_folio_links.first&.refresh || false
      end

      def existing_part_label
        existing_folio_links.first&.partLabel.to_s
      end

      def existing_sort_key
        existing_folio_links.first&.sortKey.to_s
      end

      def existing_barcode
        cocina_object.try(:identification)&.try(:barcode).to_s
      end

      # New values parsed from the CSV row

      def new_folio_instance_hrids
        @new_folio_instance_hrids ||= begin
          hrid_column_indices = row.headers.each_index.select { |i| row.headers[i] == FOLIO_HRID_COLUMN }
          row.fields(*hrid_column_indices).compact.map(&:strip).reject(&:empty?)
        end
      end

      def new_refresh?
        row['refresh']&.downcase != 'false'
      end

      def new_part_label
        row['part_label']&.strip.to_s
      end

      def new_sort_key
        row['sort_key']&.strip.to_s
      end

      def new_barcode
        row['barcode']&.strip.presence
      end

      # Logging helpers

      def log_catalog_record_id_update
        return if existing_folio_hrids == new_folio_instance_hrids

        if new_folio_instance_hrids.present?
          log("Adding FOLIO Instance HRIDs: #{new_folio_instance_hrids.join(', ')}")
        else
          log('Removing FOLIO Instance HRIDs')
        end
      end

      def log_barcode_update
        return unless cocina_object.dro?
        return if existing_barcode == new_barcode.to_s

        if new_barcode.present?
          log("Adding barcode: #{new_barcode}")
        else
          log('Removing barcode')
        end
      end
    end
  end
end
