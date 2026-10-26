# frozen_string_literal: true

module BulkActions
  # Controller for create virtual object bulk action.
  class CreateVirtualObjectController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::CREATE_VIRTUAL_OBJECT
    end

    def job_params
      { csv_file: @bulk_action_form.normalized_csv_file }
    end
  end
end
