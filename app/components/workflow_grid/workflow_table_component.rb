# frozen_string_literal: true

module WorkflowGrid
  # Render a table for a workflow's processes and their counts
  class WorkflowTableComponent < ApplicationComponent
    # @param workflow_name [String] the name of the workflow, e.g., accessionWF
    # @param template [Hash] the workflow template from Dor::Services::Client
    # @param search_form [SearchForm] the search form used to filter results
    # @param workflow_process_counts [SearchResults::WorkflowProcessCounts, nil] the process counts
    #   or nil (to render placeholders)
    def initialize(workflow_name:, template:, search_form:, workflow_process_counts: nil)
      @workflow_name = workflow_name
      @template = template.with_indifferent_access
      @search_form = search_form
      @workflow_process_counts = workflow_process_counts
      super()
    end

    def id
      "workflow-table-#{@workflow_name}"
    end

    attr_reader :workflow_name, :template, :search_form, :workflow_process_counts

    delegate :count_for, to: :workflow_process_counts

    def placeholder?
      workflow_process_counts.nil?
    end

    def statuses
      %w[waiting started error completed]
    end

    def render?
      return true if placeholder?

      @template[:processes].any? do |process|
        statuses.any? { |status| count_for(process_name: process[:name], status:).positive? }
      end
    end

    def workflow_path
      path_for(workflow_name)
    end

    def process_path_for(process_name)
      path_for(workflow_name, process_name)
    end

    def status_path_for(process_name, status)
      path_for(workflow_name, process_name, status)
    end

    private

    def path_for(*parts)
      search_path(search_form.with_attributes(wps_workflows: [parts.join(':')], page: nil))
    end
  end
end
