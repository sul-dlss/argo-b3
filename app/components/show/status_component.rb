# frozen_string_literal: true

module Show
  # Component for rendering the deposit status box on the show page.
  class StatusComponent < ApplicationComponent
    # @param unsaved_content_changes [Boolean] true if the object's mutable Content has unsaved changes
    def initialize(object_status_presenter:, solr_doc:, unsaved_content_changes: false)
      @object_status_presenter = object_status_presenter
      @solr_doc = solr_doc
      @unsaved_content_changes = unsaved_content_changes
      super()
    end

    attr_reader :object_status_presenter, :solr_doc, :unsaved_content_changes

    delegate :status, :workflow_error_messages, :druid, :version_editable?, to: :object_status_presenter
    delegate :item?, :agreement?, :collection?, :admin_policy?, :virtual_object?, :object_type_with_content?,
             to: :solr_doc

    def heading
      render(Show::StatusLabelComponent.new(status:))
    end

    def draft?
      status == :draft
    end

    def edit_label
      I18n.t("show.status.actions.#{edit_action}")
    end

    # Only items have an edit form so far.
    def can_edit?
      item? && editable?
    end

    def edit_path
      edit_item_path(druid)
    end

    def manage_files_button
      Show::ManageFilesButtonComponent.new(druid:, enabled: object_type_with_content? && editable?)
    end

    # Depositing would discard unsaved content changes, so they must be deposited from managing files.
    def can_deposit?
      editable? && !unsaved_content_changes_blocking_deposit?
    end

    def unsaved_content_changes_note?
      draft? && editable? && unsaved_content_changes_blocking_deposit?
    end

    def staging_failed_body
      t('show.status.staging_failed.body_html', email: helpers.mail_to(Settings.support_email))
    end

    private

    def unsaved_content_changes_blocking_deposit?
      object_type_with_content? && unsaved_content_changes
    end

    def editable?
      version_editable? && helpers.allowed_to?(:edit?, solr_doc, with: ObjectPolicy)
    end

    def edit_action
      return :edit_agreement if agreement?
      return :edit_collection if collection?
      return :edit_admin_policy if admin_policy?
      return :edit_virtual_object if virtual_object?

      :edit_item
    end
  end
end
