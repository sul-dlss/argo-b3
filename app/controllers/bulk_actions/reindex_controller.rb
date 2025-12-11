# frozen_string_literal: true

module BulkActions
  # Controller for reindex bulk action.
  class ReindexController < ApplicationController
    before_action :set_from_last_search_cookie
    before_action :set_bulk_action_config

    def new
      @bulk_action_form = ReindexForm.new
      @bulk_action_form.source = 'results' if @last_search_form.present?
    end

    def create
      @bulk_action_form = ReindexForm.new(bulk_action_params)
      if @bulk_action_form.valid?
        bulk_action = BulkAction.create!(
          action_type: REINDEX.action_type,
          description: @bulk_action_form.description,
          user: current_user
        )
        bulk_action.enqueue_job(druids:)
        flash[:toast] = "#{@bulk_action_config.label} submitted"
        redirect_to new_bulk_action_path
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def bulk_action_params
      params.expect(bulk_actions_reindex_form: %i[source druid_list description])
    end

    def druids
      if @bulk_action_form.source == 'druids'
        DruidSupport.parse_list(@bulk_action_form.druid_list)
      else
        Searchers::DruidList.call(search_form: @last_search_form)
      end
    end

    def set_bulk_action_config
      @bulk_action_config = BulkActions::REINDEX
    end
  end
end
