# frozen_string_literal: true

module BulkActions
  # Controller for manage release bulk action.
  class ManageReleaseController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::MANAGE_RELEASE
    end

    def job_params_for(bulk_action_form:)
      {
        druids: druids_for(bulk_action_form:),
        to: bulk_action_form.to,
        release: bulk_action_form.release
      }
    end
  end
end
