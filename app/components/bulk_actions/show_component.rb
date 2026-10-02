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

    delegate :completed?, :log_file?, to: :bulk_action

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

    delegate :existing_exports, to: :bulk_action

    # @return [Array<BulkActions::Export>] the CSV exports to display as tables
    def shown_exports
      return [] unless completed?

      existing_exports.select { |export| export.show && export.filename.end_with?('.csv') }
    end

    def export_csv(export)
      CSV.parse(File.read(bulk_action.export_filepath(export.key)), headers: true)
    end

    # @return [Array<String>] the row's cell values, with druid column values linked to the object show page
    def export_row_values(row)
      row.map do |header, value|
        next value unless header&.casecmp?('druid') && value.present?

        druid = DruidSupport.prefixed_druid_from(value.strip)
        helpers.link_to_object(druid, druid)
      end
    end

    def export_table_id(export)
      "bulk-action-#{export.key.to_s.dasherize}-table"
    end

    def export_tab_id(export)
      "bulk-action-#{export.key.to_s.dasherize}-tab"
    end

    def export_pane_id(export)
      "bulk-action-#{export.key.to_s.dasherize}-pane"
    end

    # @return [Boolean] true if we are need to show the tabs area with items or errors
    def tabs?
      shown_exports.present? || error_lines.present?
    end

    # @return [ActiveSupport::SafeBuffer] the heading for the status box
    def status_heading
      render StatusComponent.new(bulk_action:)
    end

    # @return [Array<String>] the lines of the log file reporting an error
    def error_lines
      return [] unless completed? && log_file?

      @error_lines ||= File.readlines(bulk_action.log_filepath, chomp: true).select { |line| line.include?("\tError:") }
    end

    # @return [Array<ActiveSupport::SafeBuffer>] download links for the log file and any exports
    def downloads
      [].tap do |downloads|
        downloads << log_file_link if log_file?
        existing_exports.each { |export| downloads << export_link(export) }
      end
    end

    def errors_tab_id
      'bulk-action-errors-tab'
    end

    def errors_pane_id
      'bulk-action-errors-pane'
    end

    def active_tab_id
      return export_tab_id(shown_exports.first) if shown_exports.present?

      errors_tab_id if error_lines.present?
    end

    private

    def log_file_link
      link_to('Log file', file_bulk_action_path(bulk_action, filename: bulk_action.log_filename), download: true)
    end

    def export_link(export)
      link_to(export.label, file_bulk_action_path(bulk_action, filename: export.filename), download: true)
    end
  end
end
