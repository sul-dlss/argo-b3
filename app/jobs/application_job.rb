# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # @param [String] title toast message to display
  # @param [User] user recipient of the notification
  # @param [Boolean] disappearing whether the toast auto-dismisses
  def broadcast_toast(title:, user:, disappearing: true)
    component = SdrViewComponents::Elements::ToastComponent.new(title:, disappearing:)
    Turbo::StreamsChannel.broadcast_append_to('notifications', user,
                                              target: 'toast-container',
                                              html: ApplicationController.render(component, layout: false))
  end
end
