# frozen_string_literal: true

module MultiItemDeposit
  # Component for rendering the Multi-Item Deposits history section
  class HistorySectionComponent < ApplicationComponent
    def initialize(multi_item_deposit_actions:, filter_form:)
      @multi_item_deposit_actions = multi_item_deposit_actions
      @filter_form = filter_form
      super()
    end

    attr_reader :multi_item_deposit_actions, :filter_form

    delegate :current_page, :total_pages, :limit_value, :total_count, to: :multi_item_deposit_actions
    delegate :admin?, to: :filter_form

    def path_func
      ->(new_page) { multi_item_deposit_actions_path(page: new_page, **filter_params) }
    end

    def data
      {
        controller: 'reload-interval',
        reload_interval_interval_value: Settings.reload_intervals.multi_item_deposit_actions_history.to_i
      }
    end

    def values_for(multi_item_deposit_action)
      values = [
        link_to(multi_item_deposit_action.name, multi_item_deposit_action_path(multi_item_deposit_action)),
        helpers.format_datetime(multi_item_deposit_action.created_at),
        helpers.format_datetime(multi_item_deposit_action.initiating_deposit_completed_at),
        MultiItemDepositAction::DISPLAY_STATUSES.fetch(multi_item_deposit_action.display_status),
        workflow_status_link_for(multi_item_deposit_action)
      ]
      # Admins see the Multi-Item Deposits of other users, so the user follows the name.
      values.insert(1, multi_item_deposit_action.user.sunetid) if admin?
      values
    end

    def heading
      I18n.t('multi_item_deposit_actions.history.heading')
    end

    def empty_message
      I18n.t('multi_item_deposit_actions.history.empty')
    end

    private

    # Pagination links retain the filters that do not select all options.
    def filter_params
      params = filter_form.active_filter_params
      return {} if params.empty?

      { filter_form.model_name.param_key => params }
    end

    # Without Item Deposits, the workflow grid would not be limited to any objects.
    def workflow_status_link_for(multi_item_deposit_action)
      return unless multi_item_deposit_action.item_deposit_actions.exists?

      link_to('Workflow status', workflow_grid_path(multi_item_deposit_action_ids: [multi_item_deposit_action.id]))
    end
  end
end
