# frozen_string_literal: true

module BulkActions
  # Controller for manage embargo bulk action.
  class ManageEmbargoController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::MANAGE_EMBARGO
    end

    def job_params
      {
        csv_file: @bulk_action_form.normalized_csv_file,
        close_version: @bulk_action_form.close_version
      }
    end
  end
end
