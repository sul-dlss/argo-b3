# frozen_string_literal: true

module Item
  # Component for rendering the footer of a pane of the manage files form (Item::EditTabFooterComponent with
  # buttons that are disabled while there are unassociated files or while uploading, and a cancel button that
  # discards the unsaved changes).
  class ManageFilesTabFooterComponent < ApplicationComponent
    # @param pane [SdrViewComponents::TabForm::PaneComponent] The pane component the footer is rendered in
    # @param form_id [String] The id of the form that the buttons submit
    # @param druid [String] The druid of the item
    # @param content_token [String] The signed id of the mutable Content
    # @param draft_actions_presenter [DraftActionsPresenter] The discard draft or purge button
    # @param show_next [Boolean] If next button is rendered (defaults to true)
    # @param show_previous [Boolean] If previous button is rendered (defaults to true)
    # @param show_deposit [Boolean] If deposit button is rendered (defaults to false)
    def initialize(pane:, form_id:, druid:, content_token:, draft_actions_presenter:, # rubocop:disable Metrics/ParameterLists
                   show_next: true, show_previous: true, show_deposit: false)
      @pane = pane
      @form_id = form_id
      @druid = druid
      @content_token = content_token
      @draft_actions_presenter = draft_actions_presenter
      @show_next = show_next
      @show_previous = show_previous
      @show_deposit = show_deposit
      super()
    end

    def call
      render Item::EditTabFooterComponent.new(pane:, form_id:, cancel_path: content_unsaved_changes_path(content_token),
                                              druid:, draft_actions_presenter:, show_next:, show_previous:,
                                              show_deposit:, cancel_data:,
                                              submit_data: { unassociated_files_target: 'submit' },
                                              actions_data: { disable_actions_target: 'disableable' })
    end

    private

    attr_reader :pane, :form_id, :druid, :content_token, :draft_actions_presenter, :show_next, :show_previous,
                :show_deposit

    def cancel_data
      { turbo_method: :delete, turbo_confirm: t('edit.contents.edit.buttons.cancel_confirm'),
        disable_actions_target: 'disableable' }
    end
  end
end
