# frozen_string_literal: true

module Sdr
  # Service to interact with the SDR event service.
  # Events are published to RabbitMQ, where they are consumed by dor-services-app.
  class Event
    class Error < StandardError; end

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
  end
end
