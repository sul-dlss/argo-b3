# frozen_string_literal: true

# Job that deletes Notifications older than the retention period.
class NotificationsCleanupJob < ApplicationJob
  RETENTION_PERIOD = 30.days

  queue_as :cleanup

  def perform
    # An event's notifications are created with it, so deleting an old event deletes its old notifications.
    Noticed::Event.where(created_at: ...RETENTION_PERIOD.ago).in_batches.destroy_all
  end
end
