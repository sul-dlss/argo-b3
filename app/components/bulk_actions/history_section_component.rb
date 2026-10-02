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
        render(StatusComponent.new(bulk_action:)),
        "#{bulk_action.druid_count_total} / #{bulk_action.druid_count_success} / #{bulk_action.druid_count_fail}",
        download_links_for(bulk_action)
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
      return unless bulk_action.log_file?

      link_to('Log file', file_bulk_action_path(bulk_action, filename: bulk_action.log_filename), download: true)
    end

    def export_links_for(bulk_action)
      return unless bulk_action.existing_exports

      bulk_action.existing_exports.map do |export|
        link_to(export.label, file_bulk_action_path(bulk_action, filename: export.filename), download: true)
      end
    end

    def download_links_for(bulk_action)
      links = Array(log_file_link_for(bulk_action)) + Array(export_links_for(bulk_action)).compact
      return if links.blank?

      tag.ul { safe_join(links.map { |link| tag.li(link) }) }
    end
  end
end
