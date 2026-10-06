# frozen_string_literal: true

module Show
  # Component for rendering the events table on the show page.
  # Rows for events with data can be clicked to show / hide the data.
  class EventsTableComponent < ApplicationComponent
    # @param events [Array<Dor::Services::Client::Events::Event>]
    def initialize(events:)
      @events = events
      super()
    end

    attr_reader :events

    def when_label(event)
      helpers.format_datetime(Time.zone.parse(event.timestamp))
    end

    def event_type_label(event)
      event.event_type.humanize
    end

    def who(event)
      event.data&.dig('who')
    end

    def version(event)
      event.data&.dig('version')
    end

    # Who and version are excluded since they are displayed in their own columns.
    def display_data(event)
      (event.data || {}).except('who', 'version')
    end

    def data?(event)
      display_data(event).present?
    end

    def data_id(index)
      "event-#{index}-data"
    end

    def key_label(key)
      key.to_s.humanize
    end

    def json?(value)
      value.is_a?(Hash) || value.is_a?(Array)
    end

    # Chevron indicating whether the data is shown, styled like a Bootstrap accordion button.
    def toggle_indicator(event)
      return unless data?(event)

      tag.span(class: 'event-toggle-indicator')
    end

    def toggle_row_options(event, index)
      return {} unless data?(event)

      {
        data: { bs_toggle: 'collapse', bs_target: "##{data_id(index)}" },
        aria: { expanded: false, controls: data_id(index) },
        class: 'event-toggle collapsed'
      }
    end
  end
end
