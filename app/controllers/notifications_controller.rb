# frozen_string_literal: true

# Controller for the current user's Notifications.
class NotificationsController < ApplicationController
  RECENT_LIMIT = 25

  # No reason to authorize since each action shows only the current user's own Notifications or settings.
  skip_verify_authorized

  def index
    @notifications = Current.user.notifications
                            .where(created_at: NotificationsCleanupJob::RETENTION_PERIOD.ago..)
                            .includes(event: :record)
                            .newest_first
                            .limit(RECENT_LIMIT)
  end

  def email_settings; end
end
