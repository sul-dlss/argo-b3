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

    delegate :completed?, :log_file?, :name, to: :bulk_action

    def data
      return {} if completed?

      {
        controller: 'scheduled-refresh',
        scheduled_refresh_interval_value: Settings.reload_intervals.bulk_action_show.to_i
      }
    end

    def action_label
      "#{bulk_action.bulk_action_config.label} bulk action"
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

    # @return [Array<String>] the row's cell values, with druids shown bare and linked to the object show page
    def export_row_values(row)
      row.map do |header, value|
        next value unless header&.casecmp?('druid') && value.present?

        druid = DruidSupport.prefixed_druid_from(value.strip)
        helpers.link_to_object(DruidSupport.bare_druid_from(druid), druid)
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

    # @return [Boolean] true if we need to show the tabs area with exports, successes, or errors
    def tabs?
      shown_exports.present? || success_lines.present? || error_lines.present?
    end

    # @return [ActiveSupport::SafeBuffer] the heading for the status box
    def status_heading
      render StatusComponent.new(bulk_action:)
    end

    # @return [Array<String>] the lines of the log file reporting a success
    def success_lines
      log_lines_by_status[:success]
    end

    # @return [Array<String>] the lines of the log file reporting an error
    def error_lines
      log_lines_by_status[:error]
    end

    # @return [Array<ActiveSupport::SafeBuffer>] download links for the log file and any exports
    def downloads
      [].tap do |downloads|
        downloads << log_file_link if log_file?
        existing_exports.each { |export| downloads << export_link(export) }
      end
    end

    def successes_tab_id
      'bulk-action-successes-tab'
    end

    def successes_pane_id
      'bulk-action-successes-pane'
    end

    def errors_tab_id
      'bulk-action-errors-tab'
    end

    def errors_pane_id
      'bulk-action-errors-pane'
    end

    def active_tab_id
      return export_tab_id(shown_exports.first) if shown_exports.present?
      return successes_tab_id if success_lines.present?

      errors_tab_id if error_lines.present?
    end

    # @return [Array<Hash>] button arguments for the links that the bulk action type adds to the left nav
    def nav_links
      bulk_action.bulk_action_config.nav_links.filter_map { |key| nav_link(key) }
    end

    private

    # @param key [Symbol] a key listed in the bulk action config's nav_links
    # @return [Hash, nil] button arguments for the link, or nil when it is not shown yet
    def nav_link(key)
      case key
      when :register_more_items
        register_more_items_nav_link
      when :deposit_multiple_items
        { link: multi_item_deposit_actions_path, method: :post, label: t('multi_item_deposit_actions.new'),
          disabled: !can_register_item? }
      else
        raise ArgumentError, "Unknown nav link #{key} for #{bulk_action.action_type}"
      end
    end

    # Shown once the bulk action has completed, with the form prefilled with the registration settings of the first
    # registered item (all items share them), or blank when none was registered.
    def register_more_items_nav_link
      return unless completed?

      # A param rather than in the link, since submitting a GET form replaces its action's query string.
      { link: new_multiple_item_path, params: { from_druid: first_registered_druid }.compact,
        label: t('bulk_actions.show.register_more_items'), disabled: !can_register_item? }
    end

    def can_register_item?
      helpers.allowed_to?(:new?, nil, with: ItemPolicy)
    end

    # @return [String, nil] the druid of the first item in the registration report, which lists only registered items
    def first_registered_druid
      filepath = bulk_action.export_filepath(:registration_report)
      return unless File.exist?(filepath)

      bare_druid = CSV.foreach(filepath, headers: true).first&.fetch('Druid')
      DruidSupport.prefixed_druid_from(bare_druid) if bare_druid
    end

    # Streams the log file once, keeping only the success and error lines rather than the whole file.
    # @return [Hash{Symbol => Array<String>}] the success and error lines of the log file
    def log_lines_by_status
      @log_lines_by_status ||= { success: [], error: [] }.tap do |lines|
        next unless completed? && log_file?

        File.foreach(bulk_action.log_filepath, chomp: true) do |line|
          if line.include?("\tSuccess:")
            lines[:success] << line
          elsif line.include?("\tError:")
            lines[:error] << line
          end
        end
      end
    end

    def log_file_link
      link_to(with_bulk_action_context('Log file'),
              file_bulk_action_path(bulk_action, filename: bulk_action.log_filename), download: true)
    end

    def with_bulk_action_context(text)
      helpers.text_with_hidden_context(text, "for #{name}")
    end

    def export_link(export)
      link_to(with_bulk_action_context(export.label), file_bulk_action_path(bulk_action, filename: export.filename),
              download: true)
    end
  end
end
