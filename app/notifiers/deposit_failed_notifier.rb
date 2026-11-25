# frozen_string_literal: true

# Notifies the depositing user that a Single-Object Deposit has gone In Error: staging failed (from StageFilesJob),
# or its Tracked Deposit went from no Process in error to some (from PollTrackedDepositsJob). It has no record; the
# object is identified by the druid and version in its params. Delivered by TrackedDeposit.
#
# The email is sent 10 minutes later, unless the Deposit has left In Error since the Notification: staging was
# retried, the Process was retried, or the Deposit is no longer tracked (e.g., it is Complete or the draft was
# discarded). If it went In Error again since, that later error has its own Notification and email. The email is
# also skipped when the depositing user has turned off Deposit failed emails.
class DepositFailedNotifier < ApplicationNotifier
  EMAIL_WAIT = 10.minutes

  self.email_notifier_kind = 'deposit_failed'

  # title is the object's title when the Deposit went In Error; cause is one of TrackedDeposit::CAUSES;
  # error_summary is what went wrong (for Processes, each as workflow:process:message).
  required_params :druid, :version, :title, :cause, :error_summary

  deliver_by :turbo_toast, class: 'DeliveryMethods::TurboToast', queue: :real_time
  deliver_by :email, mailer: 'NotificationMailer', method: :deposit_failed,
                     wait: EMAIL_WAIT, unless: :skip_email?

  # Evaluated when the email is due.
  # @return [Boolean] whether the email should not be sent
  def skip_email?(notification)
    email_turned_off?(notification) || left_error_since_notification?(notification)
  end

  # Evaluated when the email is due.
  # @return [Boolean] whether the Deposit has left In Error since the Notification
  def left_error_since_notification?(_notification)
    tracked_deposit = TrackedDeposit.find_by(druid: params[:druid], version: params[:version])
    return true unless tracked_deposit&.in_error_since?(cause: params[:cause], time: created_at)

    # PollTrackedDepositsJob runs about as often as the email waits, so it may not yet have seen a retry.
    params[:cause] == 'process' && process_errors.empty?
  end

  private

  def process_errors
    Sdr::WorkflowService.process_errors(druid: params[:druid], version: params[:version])
  end

  notification_methods do
    def title
      I18n.t('notifiers.deposit_failed.title')
    end

    def text
      link = subject_link(I18n.t('notifiers.deposit_failed.text', label: subject_label, version: params[:version]),
                          subject_path)
      ActionController::Base.helpers.safe_join([link, detail], ' ')
    end

    def subject_label
      I18n.t('notifiers.deposit_failed.subject_label', title: params[:title],
                                                       bare_druid: DruidSupport.bare_druid_from(params[:druid]))
    end

    def subject_path
      object_path(params[:druid])
    end

    # The staging failure's summary already says what to do.
    def detail
      return params[:error_summary] unless params[:cause] == 'process'

      I18n.t('notifiers.deposit_failed.process_errors', errors: params[:error_summary].delete_suffix('.'),
                                                        email: Settings.support_email)
    end

    def error?
      true
    end
  end
end
