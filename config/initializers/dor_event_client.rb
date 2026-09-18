# frozen_string_literal: true

# Configure dor-event-client to use the RabbitMQ instance that dor-services-app consumes events from
Dor::Event::Client.configure(hostname: Settings.rabbitmq.hostname,
                             vhost: Settings.rabbitmq.vhost,
                             username: Settings.rabbitmq.username,
                             password: Settings.rabbitmq.password)
