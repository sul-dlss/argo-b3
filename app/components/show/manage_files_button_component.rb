# frozen_string_literal: true

module Show
  # Component for the status box's manage files button, which links to managing files only when enabled, opening on
  # structure files (see Contents::ManageFilesFlow#open_on!).
  class ManageFilesButtonComponent < ApplicationComponent
    # @param label [String] the name of managing files for the object (see ManageFilesHelper)
    def initialize(druid:, label:, enabled:)
      @druid = druid
      @label = label
      @enabled = enabled
      super()
    end

    attr_reader :label

    def enabled?
      @enabled
    end

    def path
      edit_content_path(druid, open_on: Contents::ManageFilesFlow::OPEN_ON_STRUCTURE)
    end

    private

    attr_reader :druid
  end
end
