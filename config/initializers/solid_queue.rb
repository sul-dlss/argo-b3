# frozen_string_literal: true

# How long the SolidQueue supervisor waits for in-flight jobs to finish on
# shutdown before force-terminating them. Kamal's job role stop_timeout
# (config/deploy.qa.yml) is set to match, so Docker's SIGKILL doesn't cut
# this grace period short.
SolidQueue.shutdown_timeout = ENV.fetch('SOLID_QUEUE_SHUTDOWN_TIMEOUT', 86_400).to_i
