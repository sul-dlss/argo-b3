# frozen_string_literal: true

# Notifies the depositing user that a Single-Object Deposit has gone In Error: staging failed (from StageFilesJob),
# or its Tracked Deposit went from no Process in error to some (from PollTrackedDepositsJob). It has no record; the
# object is identified by the druid and version in its params. Delivered by TrackedDeposit.
#
# The email is sent 10 minutes later, unless the Deposit has left In Error since the Notification: staging was
# retried, the Process was retried, or the Deposit is no longer tracked (e.g., it is Complete or the draft was
# discarded). If it went In Error again since, that later error has its own Notification and email.
class DepositFailedNotifier < ApplicationNotifier
  EMAIL_WAIT = 10.minutes

  # title is the object's title when the Deposit went In Error; cause is one of TrackedDeposit::CAUSES;
  # error_summary is what went wrong (for Processes, each as workflow:process:message).
  required_params :druid, :version, :title, :cause, :error_summary

  deliver_by :turbo_toast, class: 'DeliveryMethods::TurboToast', queue: :real_time
  deliver_by :email, mailer: 'NotificationMailer', method: :deposit_failed,
                     wait: EMAIL_WAIT, unless: :left_error_since_notification?

  # Evaluated when the email is due.
  # @return [Boolean] whether the Deposit has left In Error since the Notification
  def left_error_since_notification?(_notification)
    tracked_deposit = TrackedDeposit.find_by(druid: params[:druid], version: params[:version])
    !tracked_deposit&.in_error_since?(cause: params[:cause], time: created_at)
  end

  notification_methods do
    def title
      I18n.t('notifiers.deposit_failed.title')
    end

    def text
      link = subject_link(I18n.t('notifiers.deposit_failed.text', label: subject_label, version: params[:version]),
                          subject_path)
      ActionController::Base.helpers.safe_join([link, params[:error_summary]], ' ')
    end

    def subject_label
      I18n.t('notifiers.deposit_failed.subject_label', title: params[:title],
                                                       bare_druid: DruidSupport.bare_druid_from(params[:druid]))
    end

    def subject_path
      object_path(params[:druid])
    end

    def detail
      params[:error_summary]
    end

    def error?
      true
    end
  end
end
