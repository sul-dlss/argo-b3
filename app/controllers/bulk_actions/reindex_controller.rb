# frozen_string_literal: true

module BulkActions
  # Controller for reindex bulk action.
  class ReindexController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::REINDEX
    end

    def job_params
      { druids: druids_from_form }
    end
  end
end
