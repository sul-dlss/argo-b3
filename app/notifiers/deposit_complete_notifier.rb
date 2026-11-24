# frozen_string_literal: true

# Notifies the depositing user that a Single-Object Deposit is Complete. It has no record; the object is identified
# by the druid and version in its params. Delivered from PollTrackedDepositsJob.
class DepositCompleteNotifier < ApplicationNotifier
  # title is the object's title when the Deposit completed.
  required_params :druid, :version, :title

  deliver_by :turbo_toast, class: 'DeliveryMethods::TurboToast', queue: :real_time

  notification_methods do
    def title
      I18n.t('notifiers.deposit_complete.title')
    end

    def text
      subject_link(I18n.t('notifiers.deposit_complete.text', label: subject_label, version: params[:version]),
                   subject_path)
    end

    def subject_label
      I18n.t('notifiers.deposit_complete.subject_label', title: params[:title],
                                                         bare_druid: DruidSupport.bare_druid_from(params[:druid]))
    end

    def subject_path
      object_path(params[:druid])
    end

    def detail
      I18n.t('notifiers.deposit_complete.detail', version: params[:version])
    end
  end
end
