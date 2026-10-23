# frozen_string_literal: true

module Item
  # Component for rendering the footer of a pane of the item edit form: the tab based navigation
  # and the buttons for saving as a draft, discarding the draft, and (optionally) depositing.
  class EditTabFooterComponent < ApplicationComponent
    # @param pane [SdrViewComponents::TabForm::PaneComponent] The pane component the footer is rendered in
    # @param form_id [String] The id of the form that the buttons submit
    # @param cancel_path [String] The URL for the cancel button
    # @param discard_path [String] The URL for discarding the draft
    # @param show_next [Boolean] If next button is rendered (defaults to true)
    # @param show_previous [Boolean] If previous button is rendered (defaults to true)
    # @param show_deposit [Boolean] If deposit button is rendered (defaults to false)
    def initialize(pane:, form_id:, cancel_path:, discard_path:, # rubocop:disable Metrics/ParameterLists
                   show_next: true, show_previous: true, show_deposit: false)
      @pane = pane
      @form_id = form_id
      @cancel_path = cancel_path
      @discard_path = discard_path
      @show_next = show_next
      @show_previous = show_previous
      @show_deposit = show_deposit
      super()
    end

    attr_reader :pane, :form_id, :cancel_path, :discard_path, :show_next, :show_previous, :show_deposit
  end
end
