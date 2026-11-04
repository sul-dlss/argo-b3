# frozen_string_literal: true

module BulkActions
  # Controller for import tags bulk action.
  class ImportTagsController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::IMPORT_TAGS
    end

    def job_params
      { csv_file: @bulk_action_form.normalized_csv_file }
    end
  end
end
