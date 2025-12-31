# frozen_string_literal: true

module BulkActions
  # Controller for open version bulk action.
  class OpenVersionController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::OPEN_NEW_VERSION
    end

    def job_params
      {
        druids: druids_from_form,
        version_description: @bulk_action_form.version_description
      }
    end
  end
end
