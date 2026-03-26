# frozen_string_literal: true

module BulkActions
  # Controller for update source id bulk action.
  class ManageSourceIdController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::MANAGE_SOURCE_ID
    end

    def job_params
      {
        csv_file: @bulk_action_form.normalized_csv_file,
        close_version: @bulk_action_form.close_version
      }
    end
  end
end
