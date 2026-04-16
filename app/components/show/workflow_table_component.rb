# frozen_string_literal: true

module Show
  # Component for rendering a workflow table on the show page.
  class WorkflowTableComponent < ApplicationComponent
    def initialize(workflow:, version:, processes:)
      @workflow = workflow
      @version = version
      @processes = processes
      super()
    end

    attr_reader :workflow, :version, :processes

    delegate :workflow_name, to: :workflow

    def table_id
      "#{workflow_name.parameterize}-#{version}-table"
    end
  end
end
