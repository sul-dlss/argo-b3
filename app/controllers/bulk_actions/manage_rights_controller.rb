# frozen_string_literal: true

module BulkActions
  # Controller for manage rights bulk action.
  class ManageRightsController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::MANAGE_RIGHTS
    end

    def job_params
      {
        druids: druids_from_form,
        close_version: @bulk_action_form.close_version,
        view: @bulk_action_form.view,
        download: @bulk_action_form.download,
        location: @bulk_action_form.location
      }
    end
  end
end
