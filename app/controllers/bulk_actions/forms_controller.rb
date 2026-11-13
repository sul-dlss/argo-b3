# frozen_string_literal: true

module BulkActions
  # New and create for the bulk action named by the route's bulk_action_type (see BulkActions).
  class FormsController < ApplicationController
    skip_verify_authorized
    before_action :set_from_last_search_cookie
    before_action :set_example_druids
    before_action :set_bulk_action_config
    before_action :set_form_options

    def new
      authorize_bulk_action!
      @bulk_action_form = form_class.new
      @bulk_action_form.source = 'results' if @last_search_form.present? && @bulk_action_form.respond_to?(:source=)
      render_form
    end

    def create
      authorize_bulk_action!
      @bulk_action_form = form_class.new(form_class.params_from(params))
      if @bulk_action_form.valid?
        create_bulk_action
        @bulk_action.enqueue_job(**job_params)
        flash[:toast] = "#{@bulk_action_config.label} submitted"
        redirect_to bulk_actions_path
      else
        render_form(status: :unprocessable_content)
      end
    end

    private

    # Subclasses may override to set instance variables (e.g., select options) needed to render the form.
    def set_form_options; end

    def set_bulk_action_config
      @bulk_action_config = BulkActions.find_config(request.path_parameters[:bulk_action_type])
    end

    def authorize_bulk_action!
      return if @bulk_action_config.admin_policy_rule.nil?

      authorize! to: @bulk_action_config.admin_policy_rule, with: AdminPolicy
    end

    def form_class
      @bulk_action_config.form
    end

    # Renders the bulk action's own new view (bulk_actions/<key>/new) if it has one, else the default form.
    def render_form(status: :ok)
      template = "bulk_actions/#{@bulk_action_config.key}/new"
      render template_exists?(template) ? template : 'bulk_actions/forms/new', status:
    end

    # @return [Hash] the parameters to pass to the bulk action job
    def job_params
      @bulk_action_form.job_params.tap do |job_params|
        job_params[:druids] = druids_from_form if @bulk_action_form.is_a?(BasicForm)
        job_params[:close_version] = @bulk_action_form.close_version if @bulk_action_config.close_version?
      end
    end

    # Gets the druids to process for the bulk action based on the form input.
    def druids_from_form
      if @bulk_action_form.source == 'druids'
        DruidSupport.parse_list(@bulk_action_form.druid_list)
      else
        Searchers::DruidList.call(search_form: @last_search_form.without(:page),
                                  user_scope: current_user_scope)
      end
    end

    def set_example_druids
      return if @last_search_form.blank?

      @example_druids = Searchers::DruidList.call(search_form: @last_search_form.without(:page),
                                                  user_scope: current_user_scope, limit: 6)
    end

    def create_bulk_action
      @bulk_action = BulkAction.create!(
        action_type: @bulk_action_config.action_type,
        description: @bulk_action_form.description,
        user: current_user
      )
    end
  end
end
