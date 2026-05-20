# frozen_string_literal: true

module BulkActions
  # Controller for refresh metadata bulk action.
  class RefreshMetadataController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::REFRESH_METADATA
    end

    def job_params
      {
        druids: druids_from_form,
        close_version: @bulk_action_form.close_version
      }
    end
  end
end
