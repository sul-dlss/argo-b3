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

    def heading
      I18n.t('multi_item_deposit_actions.history.heading')
    end

    private

    # Pagination links retain the filters that do not select all options.
    def filter_params
      params = filter_form.active_filter_params
      return {} if params.empty?

      { filter_form.model_name.param_key => params }
    end
  end
end
