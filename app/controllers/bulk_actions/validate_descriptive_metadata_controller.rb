# frozen_string_literal: true

module BulkActions
  # Controller for validate descriptive metadata bulk action.
  class ValidateDescriptiveMetadataController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::VALIDATE_DESCRIPTIVE_METADATA
    end

    def job_params
      { csv_file: @bulk_action_form.normalized_csv_file }
    end
  end
end
