# frozen_string_literal: true

module BulkActions
  # Controller for export descriptive metadata bulk action.
  class ExportDescriptiveMetadataController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::EXPORT_DESCRIPTIVE_METADATA
    end

    def job_params
      { druids: druids_from_form }
    end
  end
end
