# frozen_string_literal: true

module BulkActions
  # Controller for close version bulk action.
  class CloseVersionController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::CLOSE_VERSION
    end

    def job_params
      { druids: druids_from_form }
    end
  end
end
