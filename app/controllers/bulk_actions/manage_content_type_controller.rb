# frozen_string_literal: true

module BulkActions
  # Controller for manage content type bulk action.
  class ManageContentTypeController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::MANAGE_CONTENT_TYPE
    end

    def job_params
      {
        druids: druids_from_form,
        close_version: @bulk_action_form.close_version,
        current_resource_type: @bulk_action_form.current_resource_type.presence,
        new_content_type: @bulk_action_form.new_content_type.presence,
        new_resource_type: @bulk_action_form.new_resource_type.presence,
        viewing_direction: @bulk_action_form.viewing_direction.presence
      }
    end
  end
end
