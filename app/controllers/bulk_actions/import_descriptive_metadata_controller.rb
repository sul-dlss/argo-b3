# frozen_string_literal: true

module BulkActions
  # Controller for import descriptive metadata bulk action.
  class ImportDescriptiveMetadataController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::IMPORT_DESCRIPTIVE_METADATA
    end

    def job_params
      {
        csv_file: @bulk_action_form.normalized_csv_file,
        close_version: @bulk_action_form.close_version
      }
    end
  end
end
