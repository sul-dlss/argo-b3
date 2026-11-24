# frozen_string_literal: true

module Notifications
  # Table of a user's recent Notifications: their subject, outcome and title with any detail, and when they were sent.
  class RecentTableComponent < ApplicationComponent
    # @param notifications [Array<Noticed::Notification>] the Notifications, in the order to list them
    def initialize(notifications:)
      @notifications = notifications
      super()
    end

    attr_reader :notifications

    # @return [ActiveSupport::SafeBuffer] a decorative icon for the Notification's outcome (its title has the meaning)
    def outcome_icon(notification)
      if notification.error?
        helpers.danger_icon(classes: 'text-danger me-1', aria: { hidden: true })
      else
        helpers.success_icon(classes: 'text-success me-1', aria: { hidden: true })
      end
    end

    # @return [ActiveSupport::SafeBuffer] how long ago the Notification was sent, with the exact time on hover
    def time_ago(notification)
      tag.time(t('notifications.recent.time_ago', time: helpers.time_ago_in_words(notification.created_at)),
               datetime: notification.created_at.iso8601,
               title: helpers.format_datetime(notification.created_at, format: :date_time))
    end
  end
end
