# frozen_string_literal: true

module Item
  # Component for rendering the tab based navigation on registration form
  class TabNavigationComponent < ApplicationComponent
    # @param pane [SdrViewComponents::TabForm::PaneComponent] The pane component the nav is rendered in
    # @param cancel_path [String] The URL for the cancel button
    # @param show_next [Boolean] If next button is rendered (defaults to true)
    # @param show_previous [Boolean] If previous button is rendered (defaults to true)
    def initialize(pane:, cancel_path:, show_next: true, show_previous: true)
      @pane = pane
      @cancel_path = cancel_path
      @show_next = show_next
      @show_previous = show_previous
      super()
    end

    attr_reader :pane, :cancel_path, :show_next, :show_previous
  end
end
