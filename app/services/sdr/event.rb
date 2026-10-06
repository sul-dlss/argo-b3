# frozen_string_literal: true

module Sdr
  # Service to interact with the SDR event service.
  # Events are published to RabbitMQ, where they are consumed by dor-services-app.
  # Events and event types are retrieved from dor-services-app.
  class Event
    class Error < StandardError; end
    class NotFoundResponse < Error; end

    # KAMAL_HOST is set by Kamal for deployed containers.
    # @return [String] the hostname of the server, for use as event data
    def self.host
      ENV.fetch('KAMAL_HOST') { Socket.gethostname }
    end

    # @param [String] druid the druid of the object
    # @param [String] type the type of the event, e.g., 'argo_permission_created'
    # @param [Hash] data event data
    # @raise [Error] if there is an error publishing the event
    def self.create(druid:, type:, data: {})
      return unless Settings.rabbitmq.enabled

      Dor::Event::Client.create(druid:, type:, data:)
    rescue StandardError => e
      raise Error, "Creating event failed for #{druid}: #{e.message}"
    end

    # @param [String] druid the druid of the object
    # @param [Array<String>,nil] event_types event types to filter by, or nil for all
    # @param [Time,Date,String,nil] from only events created at or after this time (inclusive)
    # @param [Time,Date,String,nil] to only events created before this time (exclusive)
    # @return [Array<Dor::Services::Client::Events::Event>] the events for the object
    # @raise [NotFoundResponse] if the object is not found
    # @raise [Error] if there is an error retrieving the events
    def self.list(druid:, event_types: nil, from: nil, to: nil)
      events = Dor::Services::Client.object(druid).events.list(event_types:, from:, to:)
      raise NotFoundResponse, "Object not found: #{druid}" if events.nil?

      events
    rescue Dor::Services::Client::Error => e
      raise Error, "Retrieving events failed for #{druid}: #{e.message}"
    end

    # @return [Array<String>] the valid event types, sorted
    # @raise [Error] if there is an error retrieving the event types
    def self.types
      Dor::Services::Client.event_types.list
    rescue Dor::Services::Client::Error => e
      raise Error, "Retrieving event types failed: #{e.message}"
    end
  end
end
