# frozen_string_literal: true

module BulkActions
  # Controller for import read restricted and edit permissions bulk action.
  class ImportReadRestrictedAndEditPermissionsController < BulkActionApplicationController
    before_action :authorize_manage_permissions!

    private

    def authorize_manage_permissions!
      authorize! :manage_permissions?, with: AdminPolicy
    end

    def bulk_action_config
      BulkActions::IMPORT_READ_RESTRICTED_AND_EDIT_PERMISSIONS
    end

    def job_params
      { csv_file: @bulk_action_form.normalized_csv_file }
    end
  end
end
