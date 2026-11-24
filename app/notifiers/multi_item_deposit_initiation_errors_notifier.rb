# frozen_string_literal: true

# Notifies the owner of a Multi-Item Deposit that Deposit Initiation's check found errors, so nothing was started.
# Delivered from a job with ApplicationJob#deliver_notification.
class MultiItemDepositInitiationErrorsNotifier < ApplicationNotifier
  # error_count is the number of MID Item Deposits with Deposit Initiation errors.
  required_params :name, :error_count

  deliver_by :turbo_toast, class: 'DeliveryMethods::TurboToast', queue: :real_time

  notification_methods do
    def title
      I18n.t('notifiers.multi_item_deposit_initiation_errors.title')
    end

    def text
      link_text = I18n.t('notifiers.multi_item_deposit_initiation_errors.text',
                         name: params[:name], count: params[:error_count],
                         formatted_count: delimited(params[:error_count]))
      subject_link(link_text, subject_path)
    end

    def subject_label
      params[:name]
    end

    def subject_path
      multi_item_deposit_action_path(record)
    end

    def detail
      I18n.t('notifiers.multi_item_deposit_initiation_errors.detail',
             count: params[:error_count], formatted_count: delimited(params[:error_count]))
    end

    def error?
      true
    end
  end
end
