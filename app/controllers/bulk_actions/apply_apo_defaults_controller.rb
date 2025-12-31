# frozen_string_literal: true

module BulkActions
  # Controller for apply APO defaults bulk action.
  class ApplyApoDefaultsController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::APPLY_APO_DEFAULTS
    end

    def job_params
      {
        druids: druids_from_form,
        close_version: @bulk_action_form.close_version
      }
    end
  end
end
