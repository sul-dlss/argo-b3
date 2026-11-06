# frozen_string_literal: true

module Show
  # Component for rendering a workflow table on the show page.
  class WorkflowTableComponent < ApplicationComponent
    # @param solr_doc [SolrDocPresenter] the object, for authorizing process actions
    def initialize(workflow:, version:, processes:, solr_doc:)
      @workflow = workflow
      @version = version
      @processes = processes
      @solr_doc = solr_doc
      super()
    end

    attr_reader :workflow, :version, :processes, :solr_doc

    delegate :workflow_name, to: :workflow

    # Processes can only be changed in the workflow's latest (active) version.
    def actions?
      processes.first.active_version?
    end

    def table_id
      "#{workflow_name.parameterize}-#{version}-table"
    end
  end
end
