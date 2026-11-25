# frozen_string_literal: true

# Notifies the owner of a Submitted Multi-Item Deposit that it has settled: every MID Item Deposit is Complete
# (complete) or In Error, with at least one In Error (with errors). Delivered from PollTrackedDepositsJob.
#
# The complete email is sent immediately; the with errors email 10 minutes later. Either is cancelled if the
# Multi-Item Deposit has unsettled since the Notification (an errored Process or staging was retried), even if it has
# settled again, since its next settling notifies afresh. Once an email has gone out, settling no longer notifies.
# The email is also skipped when the recipient has turned off Multi-Item Deposit settled emails; that still counts as
# the email having gone out, so the recipient isn't notified again on each retry.
class MultiItemDepositSettledNotifier < ApplicationNotifier
  EMAIL_WAIT = 10.minutes

  self.email_notifier_kind = 'multi_item_deposit_settled'

  # error_count is the number of MID Item Deposits In Error; item_deposit_count is the number of MID Item Deposits.
  required_params :name, :error_count, :item_deposit_count

  deliver_by :turbo_toast, class: 'DeliveryMethods::TurboToast', queue: :real_time
  deliver_by :email, mailer: 'NotificationMailer', method: :multi_item_deposit_settled,
                     wait: -> { event.email_wait }, unless: :email_cancelled?

  # @return [ActiveSupport::Duration] how long after settling the email is sent
  def email_wait
    params[:error_count].positive? ? EMAIL_WAIT : 0.seconds
  end

  # Evaluated when the email is due. An email that is not cancelled has gone out, even if the recipient's switch
  # skips it, so later settling no longer notifies.
  # @return [Boolean] whether the email is not sent
  def email_cancelled?(notification)
    return true if unsettled_since_notification?

    record.update!(settled_email_sent_at: Time.current) if record.settled_email_sent_at.nil?
    email_turned_off?(notification)
  end

  private

  # Settling again records a later settled_at.
  def unsettled_since_notification?
    record.settled_at.nil? || record.settled_at.after?(created_at)
  end

  notification_methods do
    def title
      return I18n.t('notifiers.multi_item_deposit_settled.title_with_errors') if error?

      I18n.t('notifiers.multi_item_deposit_settled.title')
    end

    def text
      link_text = if error?
                    I18n.t('notifiers.multi_item_deposit_settled.text_with_errors',
                           name: params[:name], count: params[:error_count],
                           formatted_count: delimited(params[:error_count]))
                  else
                    I18n.t('notifiers.multi_item_deposit_settled.text', name: params[:name])
                  end
      subject_link(link_text, subject_path)
    end

    def subject_label
      params[:name]
    end

    def subject_path
      multi_item_deposit_action_path(record)
    end

    def detail
      return unless error?

      I18n.t('notifiers.multi_item_deposit_settled.detail_with_errors',
             count: params[:error_count], formatted_count: delimited(params[:error_count]),
             total_count: params[:item_deposit_count], formatted_total_count: delimited(params[:item_deposit_count]))
    end

    def error?
      params[:error_count].positive?
    end
  end
end
