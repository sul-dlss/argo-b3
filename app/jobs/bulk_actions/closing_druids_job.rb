# frozen_string_literal: true

module BulkActions
  # Superclass of bulk action jobs that take druids as input and support closing versions.
  class ClosingDruidsJob < DruidsJob
    def perform(bulk_action:, druids:, close_version:, **params)
      @close_version = close_version
      super
    end

    def close_version?
      @close_version
    end
  end
end
