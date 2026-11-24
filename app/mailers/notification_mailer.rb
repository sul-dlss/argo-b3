# frozen_string_literal: true

# Emails Notifications to their recipients. Delivered by the Notifiers' `deliver_by :email`, which passes the
# Notification's record and recipient, along with the Notifier's params, as the mailer's params.
class NotificationMailer < ApplicationMailer
  # The most errors listed in an email; the rest are in the File Check report, linked from the Multi-Item Deposit.
  MAX_LISTED_ERRORS = 100

  def multi_item_deposit_file_check_finished
    @multi_item_deposit_action = params[:record]
    @with_errors = params[:error_count].positive?
    @errors = @with_errors ? listed_file_check_errors : []
    @unlisted_error_count = @with_errors ? file_check_error_count - @errors.size : 0
    @deposit_label = deposit_label

    mail to: params[:recipient].email_address, subject: file_check_finished_subject
  end

  private

  def file_check_finished_subject
    outcome = @with_errors ? 'errors' : 'complete'
    "#{description_prefix}SDR multi-item deposit #{@multi_item_deposit_action.id} file check #{outcome}"
  end

  # @return [Array<String>] the first MAX_LISTED_ERRORS File Check errors, each preceded by its druid
  def listed_file_check_errors
    # Each MID Item Deposit with errors has at least one, so no more than MAX_LISTED_ERRORS of them are needed.
    item_deposit_actions_with_errors.order(:manifest_line_number).limit(MAX_LISTED_ERRORS)
                                    .flat_map do |item_deposit_action|
      druid = DruidSupport.bare_druid_from(item_deposit_action.druid)
      item_deposit_action.structure_errors.map { |message| "#{druid}: #{message}" }
    end.first(MAX_LISTED_ERRORS)
  end

  # @return [Integer] the number of File Check errors of all MID Item Deposits
  def file_check_error_count
    item_deposit_actions_with_errors.sum(
      Arel.sql('jsonb_array_length(structural_csv_errors) + jsonb_array_length(content_type_structure_errors)')
    )
  end

  def item_deposit_actions_with_errors
    @multi_item_deposit_action.item_deposit_actions.with_structure_errors
  end

  # @return [String] the Multi-Item Deposit's number, followed by its description in parentheses if it has one
  def deposit_label
    label = "SDR multi-item deposit #{@multi_item_deposit_action.id}"
    description = @multi_item_deposit_action.description
    description.present? ? "#{label} (#{description})" : label
  end

  # @return [String] the Multi-Item Deposit's description and a space, or nothing if it has no description
  def description_prefix
    description = @multi_item_deposit_action.description
    description.present? ? "#{description} " : ''
  end
end
