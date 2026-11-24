# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # @param [String] title toast message to display
  # @param [User] user recipient of the notification
  # @param [Boolean] disappearing whether the toast auto-dismisses
  # @param [String] text optional body text for the toast
  # @param [Symbol] variant the toast color variant (e.g., :red for errors)
  def broadcast_toast(title:, user:, disappearing: true, text: nil, variant: :black)
    ToastBroadcaster.call(title:, user:, disappearing:, text:, variant:)
  end

  # Delivers a Notification on the real_time queue, so it isn't held up behind long-running jobs.
  # The work being notified about has already been done, so a failure to notify is reported rather than failing the
  # job, which a retry would perform again.
  # @param notifier_class [Class<ApplicationNotifier>] the Notifier for the kind of Notification
  # @param recipient [User] the recipient of the Notification
  # @param params [Hash] the Notifier's params, including its record
  def deliver_notification(notifier_class, recipient:, **params)
    notifier_class.with(**params).deliver(recipient, queue: :real_time)
  rescue StandardError => e
    Rails.logger.error(e.full_message)
    Honeybadger.notify(e)
  end
end
