# frozen_string_literal: true

# Emails Notifications to their recipients. Delivered by the Notifiers' `deliver_by :email`, which passes the
# Notification's record and recipient, along with the Notifier's params, as the mailer's params.
class NotificationMailer < ApplicationMailer
  # The most errors listed in an email; the rest are in the File Check report, linked from the Multi-Item Deposit.
  MAX_LISTED_ERRORS = 100

  def multi_item_deposit_file_check_finished
    @multi_item_deposit_action = params[:record]
    @with_errors = params[:error_count].positive?
    @errors = @with_errors ? file_check_errors : []
    @deposit_label = deposit_label

    mail to: params[:recipient].email_address, subject: file_check_finished_subject
  end

  private

  def file_check_finished_subject
    args = { prefix: description_prefix, id: @multi_item_deposit_action.id }
    return t('notification_mailer.multi_item_deposit_file_check_finished.subject_with_errors', **args) if @with_errors

    t('notification_mailer.multi_item_deposit_file_check_finished.subject', **args)
  end

  # @return [Array<String>] each error of the MID Item Deposits with File Check errors, preceded by its druid
  def file_check_errors
    @multi_item_deposit_action.item_deposit_actions.with_structure_errors.order(:manifest_line_number)
                              .flat_map do |item_deposit_action|
      druid = DruidSupport.bare_druid_from(item_deposit_action.druid)
      item_deposit_action.structure_errors.map { |message| "#{druid}: #{message}" }
    end
  end

  # @return [String] the Multi-Item Deposit's number, followed by its description in parentheses if it has one
  def deposit_label
    label = t('notification_mailer.multi_item_deposit_file_check_finished.deposit', id: @multi_item_deposit_action.id)
    description = @multi_item_deposit_action.description
    description.present? ? "#{label} (#{description})" : label
  end

  # @return [String] the Multi-Item Deposit's description and a space, or nothing if it has no description
  def description_prefix
    description = @multi_item_deposit_action.description
    description.present? ? "#{description} " : ''
  end
end
