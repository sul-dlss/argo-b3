# frozen_string_literal: true

module Item
  # Component for rendering the footer of a step of managing files: Item::EditTabFooterComponent with Previous and
  # Next buttons that submit to move between the steps, a cancel button that discards the unsaved changes, and
  # save buttons that are disabled while there are unassociated files or while uploading.
  class ManageFilesStepFooterComponent < ApplicationComponent
    # @param manage_files_flow [Contents::ManageFilesFlow] the steps, which decide the Previous, Next, Deposit buttons
    # @param form_id [String] The id of the form that the buttons submit
    # @param druid [String] The druid of the item
    # @param content_token [String] The signed id of the mutable Content
    # @param draft_actions_presenter [DraftActionsPresenter] The discard draft or purge button
    # @param files_required [Boolean] If Next is disabled until the content has files (see files-required)
    def initialize(manage_files_flow:, form_id:, druid:, content_token:, draft_actions_presenter:, # rubocop:disable Metrics/ParameterLists
                   files_required: false)
      @manage_files_flow = manage_files_flow
      @form_id = form_id
      @druid = druid
      @content_token = content_token
      @draft_actions_presenter = draft_actions_presenter
      @files_required = files_required
      super()
    end

    attr_reader :form_id, :druid, :draft_actions_presenter, :files_required

    def cancel_path
      content_unsaved_changes_path(@content_token)
    end

    def cancel_data
      { turbo_method: :delete, turbo_confirm: t('edit.contents.edit.buttons.cancel_confirm'),
        disable_actions_target: 'disableable' }
    end

    def show_previous?
      !@manage_files_flow.first_step?
    end

    def show_next?
      !@manage_files_flow.last_step?
    end

    def show_deposit?
      !show_next?
    end

    def next_data
      files_required ? { files_required_target: 'submit' } : {}
    end
  end
end
