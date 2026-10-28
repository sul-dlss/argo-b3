# frozen_string_literal: true

module Item
  # Component for rendering the footer of a pane of the item edit form: the tab based navigation
  # and the buttons for saving as a draft, (optionally) saving as a draft and editing files, discarding the draft
  # or purging, and (optionally) depositing.
  class EditTabFooterComponent < ApplicationComponent
    # @param pane [SdrViewComponents::TabForm::PaneComponent] The pane component the footer is rendered in
    # @param form_id [String] The id of the form that the buttons submit
    # @param cancel_path [String] The URL for the cancel button
    # @param druid [String] The druid of the item
    # @param discard_or_purge_action [Symbol, nil] :purge, :discard_draft, or nil for no discard or purge button
    # @param show_next [Boolean] If next button is rendered (defaults to true)
    # @param show_previous [Boolean] If previous button is rendered (defaults to true)
    # @param show_edit_files [Boolean] If save draft and edit files button is rendered (defaults to false)
    # @param show_deposit [Boolean] If deposit button is rendered (defaults to false)
    def initialize(pane:, form_id:, cancel_path:, druid:, discard_or_purge_action:, # rubocop:disable Metrics/ParameterLists
                   show_next: true, show_previous: true, show_edit_files: false, show_deposit: false)
      @pane = pane
      @form_id = form_id
      @cancel_path = cancel_path
      @druid = druid
      @discard_or_purge_action = discard_or_purge_action
      @show_next = show_next
      @show_previous = show_previous
      @show_edit_files = show_edit_files
      @show_deposit = show_deposit
      super()
    end

    attr_reader :pane, :form_id, :cancel_path, :druid, :discard_or_purge_action, :show_next, :show_previous,
                :show_edit_files, :show_deposit
  end
end
