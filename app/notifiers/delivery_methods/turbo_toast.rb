# frozen_string_literal: true

module DeliveryMethods
  # Delivers a Notification as a toast on the recipient's open pages.
  # Notifications that report errors are red and do not disappear.
  class TurboToast < ApplicationDeliveryMethod
    def deliver
      ToastBroadcaster.call(title: notification.title, text: notification.text, user: recipient,
                            variant: notification.error? ? :red : :black,
                            disappearing: !notification.error?)
    end
  end
end
