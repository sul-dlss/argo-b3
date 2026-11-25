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

  def email_settings
    @email_settings_form = EmailSettingsForm.for(Current.user)
  end

  def update_email_settings
    @email_settings_form = EmailSettingsForm.new(EmailSettingsForm.params_from(params))
    @email_settings_form.save!(Current.user)

    flash[:toast] = t('notifications.email_settings.toasts.saved')
    redirect_to email_settings_notifications_path, status: :see_other
  end
end
