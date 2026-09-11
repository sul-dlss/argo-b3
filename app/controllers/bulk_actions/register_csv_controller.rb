# frozen_string_literal: true

module BulkActions
  # Controller for register CSV bulk action.
  class RegisterCsvController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::REGISTER_CSV
    end

    def job_params
      {
        csv_file: @bulk_action_form.normalized_csv_file
      }
    end
  end
end
