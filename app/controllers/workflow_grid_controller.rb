# frozen_string_literal: true

# Controller for displaying the workflow grid.
#
# The workflow grid is a view of the current search (see WorkflowGridSearchForm), so the search form
# is built from the request params exactly as it is for the search results view.
#
# While any logged in user can see the workflow grid, the search scope for workflow counts and reset
# selections are restricted to readable objects by the currently logged in/impersonated user.
# Authorization itself is skipped in SearchApplicationController.
class WorkflowGridController < SearchApplicationController
  def show
    @templates = workflow_names.index_with do |name|
      template_for(name)
    end
    @facet_labels = Search::CompositeFacetLabels.call(search_form: @search_form)

    # /workflow_grid renders with placeholders.
    # /workflow_grid?placeholder=false renders with real data.
    # The initial load of the workflow grid uses placeholders for faster rendering,
    # then the turbo-frame loads itself with the placeholder parameter to get real data.
    return if placeholder?

    @workflow_process_counts = Searchers::Workflow.call(search_form: @search_form,
                                                        user_scope: current_user_scope)
  end

  # Resets workflow errors to waiting
  def reset
    @workflow_name = params[:workflow_name]
    @process_name = params[:process_name]
    ResetWorkflowErrorsJob.perform_later(search_form: @search_form, workflow_name: @workflow_name,
                                         process_name: @process_name,
                                         effective_groups: current_effective_groups)
  end

  private

  def workflow_names
    Rails.cache.fetch('workflow_names', expires_in:) do
      Dor::Services::Client.workflows.templates
    end
  end

  # @return [Hash] the workflow template (name, description, steps, etc. for the workflow)
  def template_for(workflow_name)
    Rails.cache.fetch("workflow_template-#{workflow_name}", expires_in:) do
      Dor::Services::Client.workflows.template(workflow_name)
    end
  end

  def expires_in
    24.hours
  end

  def placeholder?
    params['placeholder'] != 'false'
  end
end
