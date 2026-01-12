# frozen_string_literal: true

module BulkActions
  # Controller for export structural metadata bulk action.
  class ExportStructuralMetadataController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::EXPORT_STRUCTURAL_METADATA
    end

    def job_params
      { druids: druids_from_form }
    end
  end
end
