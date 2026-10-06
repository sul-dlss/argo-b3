# frozen_string_literal: true

module Show
  # Component for rendering the rows for an event in the events table.
  # For an event with data, the event row can be clicked to show / hide a row with the data.
  class EventRowsComponent < ApplicationComponent
    # @param event [Dor::Services::Client::Events::Event]
    # @param index [Integer] the index of the event in the table, used to identify the data row
    def initialize(event:, index:)
      @event = event
      @index = index
      super()
    end

    attr_reader :event

    def when_label
      helpers.format_datetime(Time.zone.parse(event.timestamp))
    end

    def event_type_label
      event.event_type.humanize
    end

    def who
      event.data&.dig('who')
    end

    def version
      event.data&.dig('version')
    end

    # Who and version are excluded since they are displayed in their own columns.
    def display_data
      (event.data || {}).except('who', 'version')
    end

    def data?
      display_data.present?
    end

    def data_id
      "event-#{@index}-data"
    end

    def key_label(key)
      key.to_s.humanize
    end

    def json?(value)
      value.is_a?(Hash) || value.is_a?(Array)
    end

    # Chevron indicating whether the data is shown, styled like a Bootstrap accordion button.
    def toggle_indicator
      return unless data?

      tag.span(class: 'toggle-row-indicator')
    end

    def toggle_row_options
      return {} unless data?

      {
        data: { bs_toggle: 'collapse', bs_target: "##{data_id}" },
        aria: { expanded: false, controls: data_id },
        class: 'toggle-row collapsed'
      }
    end
  end
end
