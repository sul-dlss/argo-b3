# frozen_string_literal: true

module BulkActions
  # Controller for republish bulk action.
  class RepublishController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::REPUBLISH
    end

    def job_params_for(bulk_action_form:)
      { druids: druids_for(bulk_action_form:) }
    end
  end
end
