# frozen_string_literal: true

module BulkActions
  # Controller for export catalog data bulk action.
  class ExportCatalogDataController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::EXPORT_CATALOG_DATA
    end

    def job_params
      { druids: druids_from_form }
    end
  end
end
