# frozen_string_literal: true

module BulkActions
  # Controller for export MODS XML bulk action.
  class ExportModsController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::EXPORT_MODS
    end

    def job_params
      { druids: druids_from_form }
    end
  end
end
