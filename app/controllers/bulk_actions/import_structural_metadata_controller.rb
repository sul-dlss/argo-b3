# frozen_string_literal: true

module BulkActions
  # Controller for import structural metadata bulk action.
  class ImportStructuralMetadataController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::IMPORT_STRUCTURAL_METADATA
    end

    def job_params
      {
        csv_file: @bulk_action_form.normalized_csv_file,
        close_version: @bulk_action_form.close_version
      }
    end
  end
end
