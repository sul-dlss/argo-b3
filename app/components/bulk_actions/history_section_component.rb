# frozen_string_literal: true

module BulkActions
  # Component for rendering the bulk actions history section
  class HistorySectionComponent < ApplicationComponent
    def initialize(bulk_actions:, filter_form:)
      @bulk_actions = bulk_actions
      @filter_form = filter_form
      super()
    end

    attr_reader :bulk_actions, :filter_form

    delegate :current_page, :total_pages, :limit_value, :total_count, to: :bulk_actions
    delegate :admin?, to: :filter_form

    def path_func
      ->(new_page) { bulk_actions_path(page: new_page, **filter_params) }
    end

    def data
      {
        controller: 'reload-interval',
        reload_interval_interval_value: Settings.reload_intervals.bulk_actions_history.to_i
      }
    end

    def heading
      I18n.t('bulk_actions.history')
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
