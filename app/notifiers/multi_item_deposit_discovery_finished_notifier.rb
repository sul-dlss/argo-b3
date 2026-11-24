# frozen_string_literal: true

# Notifies the owner of a Multi-Item Deposit that its Discovery batch has finished, with or without errors.
# Delivered from a job with ApplicationJob#deliver_notification.
class MultiItemDepositDiscoveryFinishedNotifier < ApplicationNotifier
  # error_count is the number of MID Item Deposits with Discovery errors.
  required_params :name, :error_count

  deliver_by :turbo_toast, class: 'DeliveryMethods::TurboToast', queue: :real_time

  notification_methods do
    def title
      return I18n.t('notifiers.multi_item_deposit_discovery_finished.title_with_errors') if error?

      I18n.t('notifiers.multi_item_deposit_discovery_finished.title')
    end

    def text
      link_text = if error?
                    I18n.t('notifiers.multi_item_deposit_discovery_finished.text_with_errors',
                           name: params[:name], count: params[:error_count],
                           formatted_count: ActiveSupport::NumberHelper.number_to_delimited(params[:error_count]))
                  else
                    I18n.t('notifiers.multi_item_deposit_discovery_finished.text', name: params[:name])
                  end
      subject_link(link_text, multi_item_deposit_action_path(record))
    end

    def error?
      params[:error_count].positive?
    end
  end
end
