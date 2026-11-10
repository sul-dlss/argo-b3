# frozen_string_literal: true

module Show
  # Component for rendering the rows for an event in the events table.
  # For an event with data, the event row has a button (or can be clicked) to show / hide a row with the data.
  class EventRowsComponent < ApplicationComponent
    # @param event [Dor::Services::Client::Events::Event]
    def initialize(event:)
      @event = event
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

    # Identifies the rows by the event rather than its position in the table, so that a morph refresh (e.g., after
    # filtering or when new events arrive) only morphs a row into the same event's row. Otherwise, preserving the
    # expanded / collapsed state of the rows during the morph (see cocina_model_show_controller.js) would keep the
    # attributes of a different event's rows.
    def row_id
      "event-#{event.event_type}-#{event.timestamp}".parameterize
    end

    def data_id
      "#{row_id}-data"
    end

    def key_label(key)
      key.to_s.humanize
    end

    def json?(value)
      value.is_a?(Hash) || value.is_a?(Array)
    end

    def toggle_button
      return unless data?

      render Show::ToggleRowButtonComponent.new(details_row_id: data_id,
                                                label: "Show details for #{event_type_label} event")
    end

    def toggle_row_options
      return {} unless data?

      Show::ToggleRowButtonComponent::ROW_OPTIONS
    end
  end
end
