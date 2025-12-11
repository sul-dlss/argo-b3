# frozen_string_literal: true

module WorkflowGrid
  # Component for rendering a reset button for workflow errors
  class ResetButtonComponent < ApplicationComponent
    def initialize(workflow_name:, process_name:, status:, search_form:)
      @workflow_name = workflow_name
      @process_name = process_name
      @status = status
      @search_form = search_form
      super()
    end

    attr_reader :workflow_name, :process_name, :status, :search_form

    def render?
      status == 'error'
    end

    def path
      reset_workflow_grid_path(workflow_name:, process_name:)
    end
  end
end
