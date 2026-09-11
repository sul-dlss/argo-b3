# frozen_string_literal: true

require 'csv'

module BulkActions
  # Component for showing a bulk action's details.
  class ShowComponent < ApplicationComponent
    def initialize(bulk_action:)
      @bulk_action = bulk_action
      super()
    end

    attr_reader :bulk_action

    delegate :completed?, to: :bulk_action

    def data
      return {} if completed?

      {
        controller: 'scheduled-refresh',
        scheduled_refresh_interval_value: Settings.reload_intervals.bulk_action_show.to_i
      }
    end

    def label
      bulk_action.bulk_action_config.label
    end

    def show_export?
      completed? &&
        bulk_action.bulk_action_config.show_export &&
        bulk_action.export_file? &&
        bulk_action.export_filename.ends_with?('.csv')
    end

    def export_csv
      @export_csv ||= CSV.parse(File.read(bulk_action.export_filepath), headers: true)
    end

    private

    def log_file_link
      return '' unless bulk_action.log_file?

      link_to(bulk_action.log_filename, file_bulk_action_path(bulk_action, filename: bulk_action.log_filename),
              download: true)
    end

    def export_link
      return '' unless bulk_action.export_file?

      link_to(bulk_action.export_filename,
              file_bulk_action_path(bulk_action, filename: bulk_action.export_filename), download: true)
    end
  end
end
