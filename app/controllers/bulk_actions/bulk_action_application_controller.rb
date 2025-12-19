# frozen_string_literal: true

module BulkActions
  # Base controller for bulk actions.
  class BulkActionApplicationController < ApplicationController
    skip_verify_authorized
    before_action :set_from_last_search_cookie
    before_action :set_bulk_action_config

    def new
      @bulk_action_form = form_class.new
      @bulk_action_form.source = 'results' if @last_search_form.present?
    end

    def create
      @bulk_action_form = form_class.new(expected_params)
      if @bulk_action_form.valid?
        create_bulk_action
        @bulk_action.enqueue_job(**job_params_for(bulk_action_form: @bulk_action_form))
        flash[:toast] = "#{bulk_action_config.label} submitted"
        redirect_to bulk_actions_path
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    # Subclasses must implement.
    def bulk_action_config
      # For example, BulkActions::REINDEX
      raise NotImplementedError
    end

    # Subclasses must implement.
    # @return [Hash] the parameters to pass to the bulk action job
    def job_params_for(bulk_action_form:)
      raise NotImplementedError
    end

    def form_class
      bulk_action_config.form
    end

    def expected_params
      params.expect(bulk_action_config.form.model_name.param_key => form_class.permitted_params)
    end

    # Gets the druids to process for the bulk action based on the form input.
    def druids_for(bulk_action_form:)
      if bulk_action_form.source == 'druids'
        DruidSupport.parse_list(bulk_action_form.druid_list)
      else
        Searchers::DruidList.call(search_form: @last_search_form)
      end
    end

    def set_bulk_action_config
      @bulk_action_config = bulk_action_config
    end

    def create_bulk_action
      @bulk_action = BulkAction.create!(
        action_type: bulk_action_config.action_type,
        description: @bulk_action_form.description,
        user: current_user
      )
    end
  end
end
