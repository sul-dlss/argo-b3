# frozen_string_literal: true

# Controller for displaying the workflow grid
class WorkflowGridController < ApplicationController
  include SearchFormConcern

  def show
    set_from_last_search_cookie
    set_scope
    set_search_form_for_scope

    @templates = workflow_names.index_with do |name|
      template_for(name)
    end

    # /workflow_grid renders with placeholders.
    # /workflow_grid?placeholder=false renders with real data.
    # The initial load of the workflow grid uses placeholders for faster rendering,
    # then the turbo-frame loads itself with the placeholder parameter to get real data.
    @workflow_process_counts = Searchers::Workflow.call(search_form: @search_form) unless placeholder?
  end

  # Resets workflow errors to waiting
  def reset
    set_search_form # This is from the posted search form.
    @workflow_name = params[:workflow_name]
    @process_name = params[:process_name]
    ResetWorkflowErrorsJob.perform_later(search_form: @search_form, workflow_name: @workflow_name,
                                         process_name: @process_name)
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

  def set_search_form_for_scope
    # It is already set to last search form if scope is last_search
    @search_form = SearchForm.new if @scope == 'all'
    @search_form = SearchForm.new(include_google_books: true) if @scope == 'all_gb'
  end

  def set_scope
    # Scope is provided by the scope param or a default is selected based on whether there is a last search cookie.
    @scope = if (params[:scope] == 'last_search' || params[:scope].blank?) && @last_search_form.present?
               'last_search'
             elsif params[:scope] == 'all_gb'
               'all_gb'
             else
               'all'
             end
  end

  def placeholder?
    params['placeholder'] != 'false'
  end
end
