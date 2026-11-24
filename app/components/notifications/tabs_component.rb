# frozen_string_literal: true

module Notifications
  # Tabs linking the Notifications page's Recent and Email settings tabs.
  class TabsComponent < ApplicationComponent
    TABS = %i[recent email_settings].freeze

    # @param active [Symbol] The tab of the current page (:recent or :email_settings).
    def initialize(active:)
      @active = active
      super()
    end

    def call
      render Elements::LinkTabsComponent.new(classes: 'mb-4') do |component|
        TABS.each do |tab|
          component.with_tab(label: t("notifications.tabs.#{tab}"), path: path_for(tab), active: tab == @active)
        end
      end
    end

    private

    def path_for(tab)
      tab == :recent ? notifications_path : email_settings_notifications_path
    end
  end
end
