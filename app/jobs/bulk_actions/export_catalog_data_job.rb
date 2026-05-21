# frozen_string_literal: true

require 'csv'

module BulkActions
  # A job that exports catalog data (FOLIO Instance HRIDs, barcodes, and serials metadata)
  # to CSV for one or more objects.
  class ExportCatalogDataJob < DruidsJob
    HEADERS = %w[druid folio_instance_hrid refresh part_label sort_key barcode].freeze

    def export_file
      @export_file ||= CSV.open(bulk_action.export_filepath, 'w', write_headers: true, headers: HEADERS)
    end

    # Exports catalog data for a single object
    class JobItem < BaseJobItem
      def perform
        return unless check_object_type?(allow_admin_policy: false)

        export_file << [druid, *catalog_data]
        success!(message: 'Exported catalog data')
      end

      private

      def catalog_data
        link = cocina_model.folio_catalog_links.first
        [link&.catalog_record_id, link&.refresh, link&.part_label, link&.sort_key, cocina_model.try(:barcode)]
      end
    end
  end
end
