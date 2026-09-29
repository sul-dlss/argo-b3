# frozen_string_literal: true

module BulkActions
  # Component for rendering the bulk actions history section
  class HistorySectionComponent < ApplicationComponent
    def initialize(bulk_actions:)
      @bulk_actions = bulk_actions
      super()
    end

    attr_reader :bulk_actions

    delegate :current_page, :total_pages, :limit_value, :total_count, to: :bulk_actions

    def path_func
      ->(new_page) { bulk_actions_path(page: new_page) }
    end

    def data
      {
        controller: 'bulk-actions-history',
        bulk_actions_history_interval_value: Settings.reload_intervals.bulk_actions_history.to_i
      }
    end

    def values_for(bulk_action)
      [
        show_link_for(bulk_action),
        bulk_action.bulk_action_config.label,
        bulk_action.description,
        bulk_action.status.titleize,
        "#{bulk_action.druid_count_total} / #{bulk_action.druid_count_success} / #{bulk_action.druid_count_fail}",
        log_file_link_for(bulk_action),
        export_links_for(bulk_action),
        button_to('Delete', bulk_action_path(bulk_action),
                  method: :delete,
                  data: { turbo_confirm: 'Are you sure you want to delete this bulk action?' },
                  form: { data: { action: 'turbo:submit-start->bulk-actions-history#disconnect' } },
                  class: 'btn btn-primary btn-sm')
      ]
    end

    def label
      I18n.t('bulk_actions.history')
    end

    private

    def show_link_for(bulk_action)
      link_to(helpers.format_datetime(bulk_action.created_at), bulk_action_path(bulk_action))
    end

    def log_file_link_for(bulk_action)
      return '' unless bulk_action.log_file?

      link_to('Log', file_bulk_action_path(bulk_action, filename: bulk_action.log_filename), download: true)
    end

    def export_links_for(bulk_action)
      links = bulk_action.existing_exports.map do |export|
        link_to(export.label, file_bulk_action_path(bulk_action, filename: export.filename), download: true)
      end
      safe_join(links, tag.br)
    end
  end
end
