# frozen_string_literal: true

module Item
  # Component for rendering the footer of a pane of the item edit and manage files forms: the tab based navigation
  # and the buttons for saving as a draft, (optionally) saving as a draft and editing files, discarding the draft
  # or purging, and (optionally) depositing.
  class EditTabFooterComponent < ApplicationComponent
    # @param pane [SdrViewComponents::TabForm::PaneComponent] The pane component the footer is rendered in
    # @param form_id [String] The id of the form that the buttons submit
    # @param cancel_path [String] The URL for the cancel button
    # @param druid [String] The druid of the item
    # @param discard_or_purge_presenter [DiscardOrPurgePresenter] The discard draft or purge button
    # @param show_next [Boolean] If next button is rendered (defaults to true)
    # @param show_previous [Boolean] If previous button is rendered (defaults to true)
    # @param show_edit_files [Boolean] If save draft and edit files button is rendered (defaults to false)
    # @param show_deposit [Boolean] If deposit button is rendered (defaults to false)
    # @param submit_data [Hash] Data attributes for the submit buttons
    # @param actions_data [Hash] Data attributes for the fieldset of action buttons and the discard or purge link
    def initialize(pane:, form_id:, cancel_path:, druid:, discard_or_purge_presenter:, # rubocop:disable Metrics/ParameterLists
                   show_next: true, show_previous: true, show_edit_files: false, show_deposit: false,
                   submit_data: {}, actions_data: {})
      @pane = pane
      @form_id = form_id
      @cancel_path = cancel_path
      @druid = druid
      @discard_or_purge_presenter = discard_or_purge_presenter
      @show_next = show_next
      @show_previous = show_previous
      @show_edit_files = show_edit_files
      @show_deposit = show_deposit
      @submit_data = submit_data
      @actions_data = actions_data
      super()
    end

    attr_reader :pane, :form_id, :cancel_path, :druid, :discard_or_purge_presenter, :show_next, :show_previous,
                :show_edit_files, :show_deposit, :submit_data, :actions_data
  end
end
