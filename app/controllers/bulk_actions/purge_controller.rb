# frozen_string_literal: true

module BulkActions
  # Controller for purge bulk action.
  class PurgeController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::PURGE
    end

    def job_params
      { druids: druids_from_form }
    end
  end
end
