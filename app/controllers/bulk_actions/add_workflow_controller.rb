# frozen_string_literal: true

module BulkActions
  # Controller for add workflow bulk action.
  class AddWorkflowController < BulkActionApplicationController
    def new
      super
      @workflow_options = (Constants::WORKFLOWS - %w[accessionWF registrationWF]).map { |workflow| [workflow, workflow] }
    end

    private

    def bulk_action_config
      BulkActions::ADD_WORKFLOW
    end

    def job_params
      {
        druids: druids_from_form,
        workflow_name: @bulk_action_form.workflow_name,
        close_version: @bulk_action_form.close_version
      }
    end
  end
end
