# frozen_string_literal: true

module BulkActions
  # Job to refresh descriptive metadata from the ILS (FOLIO)
  class RefreshMetadataJob < DruidsJob
    # Refresh metadata for a single object
    class JobItem < BaseJobItem
      VERSION_DESCRIPTION = 'Refresh from FOLIO'

      def perform
        return unless check_update_ability?
        return unless check_object_type?(allow_admin_policy: false)

        return failure!(message: 'Does not have a Folio Instance HRID') if folio_catalog_link&.catalog_record_id.blank?
        return failure!(message: 'Refresh is set to false') unless cocina_model.catalog_link_refresh?

        refresh!
        deposit_if_needed!

        success!(message: 'Successfully refreshed metadata')
      end

      private

      def refresh!
        refresh_service = Sdr::FolioRefreshService.new(cocina_object:, user_name: user_id,
                                                       version_description: VERSION_DESCRIPTION)
        @cocina_object = refresh_service.call
        log("Opened new version (#{VERSION_DESCRIPTION})") if refresh_service.opened_version?
      end

      def folio_catalog_link
        cocina_model.folio_catalog_links.first
      end
    end
  end
end
