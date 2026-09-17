# frozen_string_literal: true

module BulkActions
  # Controller for the redeposit bulk action.
  class RedepositController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::REDEPOSIT
    end

    def job_params
      { druids: druids_from_form }
    end
  end
end
