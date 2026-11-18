# frozen_string_literal: true

module BulkActions
  # Tabs linking the bulk actions history and menu pages.
  class TabsComponent < ApplicationComponent
    TABS = %i[history menu].freeze

    # @param active [Symbol] The tab of the current page (:history or :menu).
    def initialize(active:)
      raise ArgumentError, "Invalid tab: #{active}" unless TABS.include?(active)

      @active = active
      super()
    end

    def call
      render Elements::LinkTabsComponent.new(classes: 'mb-4') do |component|
        TABS.each do |tab|
          component.with_tab(label: t("bulk_actions.tabs.#{tab}"), path: path_for(tab), active: tab == @active)
        end
      end
    end

    private

    def path_for(tab)
      tab == :history ? bulk_actions_path : new_bulk_action_path
    end
  end
end
