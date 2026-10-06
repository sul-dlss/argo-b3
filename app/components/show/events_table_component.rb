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
  end
end
