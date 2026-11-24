# frozen_string_literal: true

# Notifies the owner of a Multi-Item Deposit that its File Check batch has finished, with or without errors.
# Delivered from a job with ApplicationJob#deliver_notification.
#
# The email is sent 10 minutes later, unless the Multi-Item Deposit has changed since the Notification (Deposit
# Initiation was started, File Check or Discovery was re-run, or a MID Item Deposit was removed), since the email
# would then be out of date. Moving between steps without running one does not cancel it. If the Multi-Item Deposit
# was deleted, its Notifications are deleted with it, so the email job is discarded.
class MultiItemDepositFileCheckFinishedNotifier < ApplicationNotifier
  EMAIL_WAIT = 10.minutes

  # error_count is the number of MID Item Deposits with File Check errors; item_deposit_count is the number of MID
  # Item Deposits that File Check checked, so that removing one cancels the email.
  required_params :name, :error_count, :item_deposit_count

  deliver_by :turbo_toast, class: 'DeliveryMethods::TurboToast', queue: :real_time
  deliver_by :email, mailer: 'NotificationMailer', method: :multi_item_deposit_file_check_finished,
                     wait: EMAIL_WAIT, unless: :changed_since_notification?

  # Evaluated when the email is due.
  # @return [Boolean] whether the Multi-Item Deposit has changed since the Notification
  def changed_since_notification?(_notification)
    deposit_initiation_started? || file_check_rerun? ||
      record.item_deposit_actions.count < params[:item_deposit_count]
  end

  private

  # Still true after returning to File Check, e.g., when Deposit Initiation found errors.
  def deposit_initiation_started?
    record.initiating_deposit_started_at.present? && record.initiating_deposit_started_at.after?(created_at)
  end

  # Re-running Discovery clears File Check's start.
  def file_check_rerun?
    record.structuring_started_at.nil? || record.structuring_started_at.after?(created_at)
  end

  notification_methods do
    def title
      return I18n.t('notifiers.multi_item_deposit_file_check_finished.title_with_errors') if error?

      I18n.t('notifiers.multi_item_deposit_file_check_finished.title')
    end

    def text
      link_text = if error?
                    I18n.t('notifiers.multi_item_deposit_file_check_finished.text_with_errors',
                           name: params[:name], count: params[:error_count],
                           formatted_count: delimited(params[:error_count]))
                  else
                    I18n.t('notifiers.multi_item_deposit_file_check_finished.text', name: params[:name])
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

      I18n.t('notifiers.multi_item_deposit_file_check_finished.detail_with_errors',
             count: params[:error_count], formatted_count: delimited(params[:error_count]))
    end

    def error?
      params[:error_count].positive?
    end
  end
end
