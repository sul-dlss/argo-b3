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

    # rubocop:disable-next Metrics/AbcSize
    def values_for(bulk_action)
      values = [
        show_link_for(bulk_action),
        bulk_action.bulk_action_config.label,
        helpers.format_datetime(bulk_action.created_at),
        render(StatusComponent.new(bulk_action:)),
        "#{bulk_action.druid_count_total} / #{bulk_action.druid_count_success} / #{bulk_action.druid_count_fail}",
        download_links_for(bulk_action),
        delete_link_for(bulk_action)
      ]
      # Admins see the bulk actions of other users, so the user follows the bulk action name.
      values.insert(1, bulk_action.user.sunetid) if admin?
      values
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

    def show_link_for(bulk_action)
      link_to(bulk_action.name, bulk_action_path(bulk_action))
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

    def delete_link_for(bulk_action)
      return unless bulk_action.completed?

      render SdrViewComponents::Elements::IconButtonFormComponent.new(link: bulk_action_path(bulk_action),
                                                                      icon: :delete,
                                                                      label: I18n.t('bulk_actions.delete'),
                                                                      method: :delete,
                                                                      confirm: I18n.t('bulk_actions.delete_confirm'),
                                                                      top: false)
    end
  end
end
