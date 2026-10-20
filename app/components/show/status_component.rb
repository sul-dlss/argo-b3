# frozen_string_literal: true

module Show
  # Component for rendering the deposit status box on the show page.
  class StatusComponent < ApplicationComponent
    def initialize(object_status_presenter:, solr_doc:)
      @object_status_presenter = object_status_presenter
      @solr_doc = solr_doc
      super()
    end

    attr_reader :object_status_presenter, :solr_doc

    delegate :status, :workflow_error_messages, :druid, :version_editable?, to: :object_status_presenter
    delegate :item?, :agreement?, :collection?, :admin_policy?, :virtual_object?, to: :solr_doc

    def heading
      render(Show::StatusLabelComponent.new(status:))
    end

    def edit_label
      I18n.t("show.status.actions.#{edit_action}")
    end

    def edit?
      item? && editable?
    end

    def edit_path
      edit_item_path(druid)
    end

    # Files are managed for items and agreements.
    def manage_files?
      item? || agreement?
    end

    def manage_files_button
      Show::ManageFilesButtonComponent.new(druid:, enabled: manage_files? && editable?)
    end

    def staging_failed_body
      t('show.status.staging_failed.body_html', email: helpers.mail_to(Settings.support_email))
    end

    private

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
