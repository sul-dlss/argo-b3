# frozen_string_literal: true

# Controller for displaying the workflow grid
class WorkflowGridController < ApplicationController
  before_action :set_from_last_search_cookie
  before_action :set_scope
  before_action :set_search_form

  def index
    @templates = workflow_names.index_with do |name|
      template_for(name)
    end
  end

  def show
    @workflow_name = params[:workflow]
    @workflow_process_counts = Searchers::Workflow.call(
      search_form: @search_form,
      workflow_name: @workflow_name
    )
    @workflow_template = template_for(@workflow_name)

    render layout: false
  end

  def reset
    Rails.logger.info "Resetting workflow process #{params[:process]} for workflow #{params[:workflow]}"
    redirect_to workflow_grid_path(params[:workflow], scope: @scope), flash: { reset: true }
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

  def set_search_form
    # It is already set to last search form if scope is last_search
    @search_form = SearchForm.new if @scope == 'all'
    @search_form = SearchForm.new(include_google_books: true) if @scope == 'all_gb'
  end

  def set_scope
    @scope = if (params[:scope] == 'last_search' || params[:scope].blank?) && @last_search_form.present?
               'last_search'
             elsif params[:scope] == 'all_gb'
               'all_gb'
             else
               'all'
             end
  end
end
