# frozen_string_literal: true

module BulkActions
  # Controller for export checksum report bulk action.
  class ExportChecksumReportController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::EXPORT_CHECKSUM_REPORT
    end

    def job_params
      { druids: druids_from_form }
    end
  end
end
