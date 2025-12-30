# frozen_string_literal: true

module BulkActions
  # Controller for export tags bulk action.
  class ExportTagsController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::EXPORT_TAGS
    end

    def job_params
      { druids: druids_from_form }
    end
  end
end
