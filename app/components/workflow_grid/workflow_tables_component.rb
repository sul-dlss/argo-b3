# frozen_string_literal: true

module WorkflowGrid
  # Component for rendering workflow tables in the workflow grid
  class WorkflowTablesComponent < ApplicationComponent
    # @param templates [Hash{String => Hash}] map of workflow names to templates
    # @param search_form [SearchForm]
    # @param scope [String] the current scope
    # @param workflow_process_counts [SearchResults::WorkflowProcessCounts, nil] if nil, placeholders will be shown
    def initialize(templates:, search_form:, scope:, workflow_process_counts: nil)
      @templates = templates
      @search_form = search_form
      @workflow_process_counts = workflow_process_counts
      @scope = scope
      super()
    end

    attr_reader :templates, :search_form, :workflow_process_counts, :scope

    def placeholder?
      workflow_process_counts.nil?
    end

    def data
      return {} if Rails.env.test? # So that reloading doesn't occur in tests.

      { controller: 'workflow-grid', action: 'turbo:frame-load->workflow-grid#start' }
    end

    def frame_src
      # When rendering the placeholder variation, set the frame src to load the actual data.
      return unless placeholder?

      workflow_grid_path(scope:, placeholder: false)
    end
  end
end
