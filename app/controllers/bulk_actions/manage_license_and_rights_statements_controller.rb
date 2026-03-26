# frozen_string_literal: true

module BulkActions
  # Controller for manage license and rights statements bulk action.
  class ManageLicenseAndRightsStatementsController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::MANAGE_LICENSE_AND_RIGHTS_STATEMENTS
    end

    def job_params
      {
        druids: druids_from_form,
        close_version: @bulk_action_form.close_version,
        change_copyright: change?(@bulk_action_form.copyright_action),
        copyright:,
        change_license: change?(@bulk_action_form.license_action),
        license:,
        change_use_and_reproduction_statement: change?(@bulk_action_form.use_and_reproduction_statement_action),
        use_and_reproduction_statement:
      }
    end

    def use_and_reproduction_statement
      return unless update?(@bulk_action_form.use_and_reproduction_statement_action)

      @bulk_action_form.use_and_reproduction_statement
    end

    def license
      return unless update?(@bulk_action_form.license_action)

      @bulk_action_form.license
    end

    def copyright
      return unless update?(@bulk_action_form.copyright_action)

      @bulk_action_form.copyright
    end

    def change?(action)
      %w[update remove].include?(action)
    end

    def update?(action)
      action == 'update'
    end
  end
end
