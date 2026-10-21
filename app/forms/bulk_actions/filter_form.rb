# frozen_string_literal: true

module BulkActions
  # Form object for filtering bulk actions.
  # The hidden fields for the selects submit a blank value, so that deselecting all options
  # can be distinguished from the default of all options.
  class FilterForm < ApplicationForm
    # Submitted date options, as key => [label, how long ago the range starts (nil for no limit)].
    SUBMITTED_DATES = {
      'all' => ['View all', nil],
      'last_7_days' => ['Last 7 days', 7.days],
      'last_month' => ['Last month', 1.month],
      'last_3_months' => ['Last 3 months', 3.months],
      'last_6_months' => ['Last 6 months', 6.months],
      'last_year' => ['Last year', 1.year]
    }.freeze

    # @return [Array<String>] the action types of all implemented bulk actions, sorted by label
    def self.all_action_types
      # Configs without a job are not yet implemented, so their action type is blank.
      BulkActions.all
                 .sort_by(&:label)
                 .map(&:action_type)
                 .compact_blank
    end

    attribute :action_types, array: true, default: -> { all_action_types }
    attribute :statuses, array: true, default: -> { BulkAction::DISPLAY_STATUSES.keys }
    attribute :submitted_date, :string, default: 'all'

    # @return [Hash] the params of the filters that limit the bulk actions
    def active_filter_params
      {
        action_types: (action_types unless all_action_types?),
        statuses: (statuses unless all_statuses?),
        submitted_date: (submitted_date unless all_submitted_dates?)
      }.compact
    end

    # @return [Hash] the filters for BulkAction.filtered, with nil for no limit
    def filters
      { action_types: action_types_filter, statuses: statuses_filter, submitted_since: }
    end

    # @return [Array<String>,nil] the action types to filter by, or nil when all action types are selected
    def action_types_filter
      selected_action_types unless all_action_types?
    end

    # @return [Array<String>,nil] the display statuses to filter by, or nil when all statuses are selected
    def statuses_filter
      selected_statuses unless all_statuses?
    end

    # @return [ActiveSupport::TimeWithZone, nil] the start of the submitted date range,
    #   or nil when not limited (View all or an unknown submitted date)
    def submitted_since
      SUBMITTED_DATES.dig(submitted_date, 1)&.ago
    end

    # @return [Array<Array(String, String)>] label and action type pairs for the action types select
    def action_type_options
      self.class.all_action_types.map { |action_type| [BulkActions.find_config(action_type).label, action_type] }
    end

    # @return [Array<Array(String, String)>] label and display status pairs for the statuses select
    def status_options
      BulkAction::DISPLAY_STATUSES.map { |status, label| [label, status] }
    end

    # @return [Array<Array(String, String)>] label and key pairs for the submitted date select
    def submitted_date_options
      SUBMITTED_DATES.map { |key, (label, _duration)| [label, key] }
    end

    private

    def selected_action_types
      action_types.compact_blank
    end

    def all_action_types?
      (self.class.all_action_types - selected_action_types).empty?
    end

    def selected_statuses
      statuses.compact_blank
    end

    def all_statuses?
      (BulkAction::DISPLAY_STATUSES.keys - selected_statuses).empty?
    end

    def all_submitted_dates?
      submitted_since.nil?
    end
  end
end
