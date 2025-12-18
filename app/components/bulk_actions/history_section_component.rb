# frozen_string_literal: true

module BulkActions
  # Component for rendering the bulk actions history section
  class HistorySectionComponent < ApplicationComponent
    def initialize(bulk_actions:)
      @bulk_actions = bulk_actions
      super()
    end

    attr_reader :bulk_actions

    def data
      {
        controller: 'bulk-actions-history',
        bulk_actions_history_interval_value: Rails.env.test? ? 500 : 10_000
      }
    end

    def values_for(bulk_action)
      [
        bulk_action.bulk_action_config.label,
        bulk_action.description,
        bulk_action.status.titleize,
        "#{bulk_action.druid_count_total} / #{bulk_action.druid_count_success} / #{bulk_action.druid_count_fail}",
        log_file_link_for(bulk_action),
        report_link_for(bulk_action),
        button_to('Delete', bulk_action_path(bulk_action),
                  method: :delete,
                  data: { turbo_confirm: 'Are you sure you want to delete this bulk action?' },
                  form: { data: { action: 'turbo:submit-start->bulk-actions-history#disconnect' } },
                  class: 'btn btn-primary btn-sm')
      ]
    end

    def label
      'Bulk actions history'
    end

    private

    def log_file_link_for(bulk_action)
      return '' unless bulk_action.log_file?

      link_to('Log', file_bulk_action_path(bulk_action, filename: bulk_action.log_filename), download: true)
    end

    def report_link_for(bulk_action)
      return '' unless bulk_action.report_file?

      link_to(bulk_action.report_label,
              file_bulk_action_path(bulk_action, filename: bulk_action.report_filename), download: true)
    end
  end
end
