# frozen_string_literal: true

module Show
  # Component for rendering the deposit status box on the show page.
  class StatusComponent < ApplicationComponent
    # @param deposit_form [DepositDraftForm] the form for depositing a Draft
    # @param unsaved_content_changes [Boolean] true if the object's mutable Content has unsaved changes
    def initialize(object_status_presenter:, solr_doc:, deposit_form:, unsaved_content_changes: false)
      @object_status_presenter = object_status_presenter
      @solr_doc = solr_doc
      @deposit_form = deposit_form
      @unsaved_content_changes = unsaved_content_changes
      super()
    end

    attr_reader :object_status_presenter, :solr_doc, :deposit_form, :unsaved_content_changes

    delegate :status, :workflow_error_messages, :druid, :version_editable?, :manage_files_label,
             to: :object_status_presenter
    delegate :agreement?, :collection?, :admin_policy?, :object_type_with_content?,
             to: :solr_doc

    def heading
      render(Show::StatusLabelComponent.new(status:))
    end

    # Registered is an open first version, so it is also a draft.
    def draft?
      status.in?(%i[registered draft])
    end

    # Only objects with files are assembled, so only they can stop in error.
    def assembly_stopped_with_error?
      object_type_with_content? && object_status_presenter.assembly_stopped_with_error?
    end

    def actions?
      status.in?(%i[deposited registered draft]) || assembly_stopped_with_error?
    end

    # Design standard deviation: AVAIL-4. Deposit is hidden, not disabled, while depositing is stopped, since a
    # stopped deposit resumes by retrying the process in error.
    def deposit_button?
      draft?
    end

    def edit_label
      I18n.t("show.status.actions.#{edit_action}")
    end

    def editable?
      (version_editable? || assembly_stopped_with_error?) && allowed_to_edit?
    end

    # @return [String] the path of the object's edit form
    def edit_path
      return edit_apo_path(druid) if admin_policy?
      return edit_agreement_path(druid) if agreement?
      return edit_collection_path(druid) if collection?

      # Items and Virtual Objects, which are edited as Items.
      edit_item_path(druid)
    end

    def manage_files_button
      Show::ManageFilesButtonComponent.new(druid:, label: manage_files_label,
                                           enabled: object_type_with_content? && editable?)
    end

    # Depositing would discard unsaved content changes, so they must be deposited from managing files.
    def can_deposit?
      editable? && !unsaved_content_changes_blocking_deposit?
    end

    def unsaved_content_changes_note?
      draft? && editable? && unsaved_content_changes_blocking_deposit?
    end

    def unsaved_content_changes_note
      I18n.t('show.status.draft.unsaved_content_changes', manage_files: manage_files_label)
    end

    def staging_failed_body
      t('show.status.staging_failed.body_html', email: helpers.mail_to(Settings.support_email))
    end

    private

    def unsaved_content_changes_blocking_deposit?
      object_type_with_content? && unsaved_content_changes
    end

    def allowed_to_edit?
      helpers.allowed_to?(:edit?, solr_doc, with: ObjectPolicy)
    end

    def edit_action
      return :edit_agreement if agreement?
      return :edit_collection if collection?
      return :edit_admin_policy if admin_policy?

      :edit_item
    end
  end
end
