# frozen_string_literal: true

module Show
  # Component for the status box's Manage files button, which links to managing files only when enabled.
  class ManageFilesButtonComponent < ApplicationComponent
    def initialize(druid:, enabled:)
      @druid = druid
      @enabled = enabled
      super()
    end

    def label
      I18n.t('show.status.actions.manage_files')
    end

    def enabled?
      @enabled
    end

    def path
      edit_content_path(druid)
    end

    private

    attr_reader :druid
  end
end
