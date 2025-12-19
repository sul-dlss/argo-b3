# frozen_string_literal: true

module BulkActions
  # Controller for export cocina json bulk action.
  class ExportCocinaJsonController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::EXPORT_COCINA_JSON
    end

    def job_params_for(bulk_action_form:)
      { druids: druids_for(bulk_action_form:) }
    end
  end
end
