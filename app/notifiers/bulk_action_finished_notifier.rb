# frozen_string_literal: true

# Notifies the user who ran a Bulk Action that its job has finished, with or without errors.
#
#   BulkActionFinishedNotifier.with(record: bulk_action, label: bulk_action.label,
#                                   failure_count: bulk_action.druid_count_fail)
#                             .deliver(bulk_action.user, queue: :real_time)
class BulkActionFinishedNotifier < ApplicationNotifier
  required_params :label, :failure_count

  # The toast is on the real_time queue, so it isn't held up behind long-running bulk action jobs.
  deliver_by :turbo_toast, class: 'DeliveryMethods::TurboToast', queue: :real_time

  notification_methods do
    def title
      return I18n.t('notifiers.bulk_action_finished.title_with_errors') if error?

      I18n.t('notifiers.bulk_action_finished.title')
    end

    def text
      link_text = if error?
                    I18n.t('notifiers.bulk_action_finished.text_with_errors', label: params[:label],
                                                                              count: params[:failure_count])
                  else
                    I18n.t('notifiers.bulk_action_finished.text', label: params[:label])
                  end
      subject_link(link_text, bulk_action_path(record))
    end

    def error?
      params[:failure_count].positive?
    end
  end
end
