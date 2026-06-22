# frozen_string_literal: true

module BulkActions
  # Controller for import catalog data bulk action.
  class ImportCatalogDataController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::IMPORT_CATALOG_DATA
    end

    def job_params
      {
        csv_file: @bulk_action_form.normalized_csv_file,
        close_version: @bulk_action_form.close_version
      }
    end
  end
end
