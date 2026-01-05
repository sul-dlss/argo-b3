# frozen_string_literal: true

module BulkActions
  # Job to add a workflow to an object
  class AddWorkflowJob < BulkActions::ClosingBulkActionJob
    def perform(bulk_action:, druids:, close_version:, workflow_name:)
      @workflow_name = workflow_name
      super
    end

    attr_reader :workflow_name

    # Adds workflow to a single object
    class AddWorkflowJobItem < BulkActions::BulkActionJobItem
      delegate :workflow_name, to: :job

      def perform
        return unless check_update_ability?

        return failure!(message: "#{workflow_name} already exists") if workflow_active?

        open_new_version_if_needed!(description: "Started #{workflow_name}")

        Dor::Services::Client.object(druid).workflow(workflow_name).create(version: cocina_object.version)
        success!(message: "Started #{workflow_name}")
      end

      def workflow_active?
        Sdr::WorkflowService.workflow_active?(druid:, wf_name: workflow_name, version: cocina_object.version)
      end
    end
  end
end
