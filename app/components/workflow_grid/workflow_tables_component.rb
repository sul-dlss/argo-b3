# frozen_string_literal: true

module WorkflowGrid
  # Component for rendering workflow tables in the workflow grid
  class WorkflowTablesComponent < ApplicationComponent
    # @param templates [Hash{String => Hash}] map of workflow names to templates
    # @param search_form [WorkflowGridSearchForm]
    # @param workflow_process_counts [SearchResults::WorkflowProcessCounts, nil] if nil, placeholders will be shown
    def initialize(templates:, search_form:, workflow_process_counts: nil)
      @templates = templates
      @search_form = search_form
      @workflow_process_counts = workflow_process_counts
      super()
    end

    attr_reader :templates, :search_form, :workflow_process_counts

    def placeholder?
      workflow_process_counts.nil?
    end

    def data
      return {} if Rails.env.test? # So that reloading doesn't occur in tests.

      {
        controller: 'workflow-grid',
        action: 'turbo:frame-load->workflow-grid#start',
        workflow_grid_interval_value: Settings.reload_intervals.workflow_grid.to_i
      }
    end

    def frame_src
      # When rendering the placeholder variation, set the frame src to load the actual data.
      # The search must be carried through so that the frame counts the same objects that the
      # current filters shown above the grid describe.
      return unless placeholder?

      # polymorphic_path rather than url_for: placeholder is not a search attribute, so it cannot be
      # carried on the form (SearchForm#with drops anything the class does not declare), and url_for
      # takes a single argument. The resolve block in routes.rb merges these options into the form's
      # attributes.
      polymorphic_path(search_form, placeholder: false)
    end
  end
end
