# frozen_string_literal: true

module Show
  # Component for rendering the buttons that retry, skip, or complete a workflow process in error.
  class WorkflowProcessActionsComponent < ApplicationComponent
    def initialize(process:, solr_doc:)
      @process = process
      @solr_doc = solr_doc
      super()
    end

    attr_reader :process, :solr_doc

    delegate :workflow_name, :name, :version, to: :process

    def render?
      process.status == 'error'
    end

    def allowed?(rule)
      helpers.allowed_to?(rule, solr_doc, with: ObjectPolicy)
    end

    def path
      object_workflow_process_path(druid: solr_doc.druid, workflow_name:, process: name)
    end

    def params_for(status)
      { status:, version: }
    end
  end
end
