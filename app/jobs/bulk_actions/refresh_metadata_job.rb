# frozen_string_literal: true

module BulkActions
  # Job to refresh descriptive metadata from the ILS (FOLIO)
  class RefreshMetadataJob < ClosingDruidsJob
    # Refresh metadata for a single object
    class JobItem < BaseJobItem
      def perform
        return unless check_update_ability?
        return unless check_object_type?(allow_admin_policy: false)

        return failure!(message: 'Does not have a Folio Instance HRID') if folio_catalog_link&.catalog_record_id.blank?
        return failure!(message: 'Refresh is set to false') unless folio_catalog_link&.refresh

        open_new_version_if_needed!(description: 'Refreshed metadata from FOLIO')

        Dor::Services::Client.object(druid).refresh_descriptive_metadata_from_ils
        close_version_if_needed!

        success!(message: 'Successfully refreshed metadata')
      end

      private

      def folio_catalog_link
        cocina_model.folio_catalog_links.first
      end
    end
  end
end
