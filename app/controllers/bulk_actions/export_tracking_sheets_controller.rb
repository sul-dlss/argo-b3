# frozen_string_literal: true

module BulkActions
  # Controller for export tracking sheets bulk action.
  class ExportTrackingSheetsController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::EXPORT_TRACKING_SHEETS
    end

    def job_params
      { druids: druids_from_form }
    end
  end
end
