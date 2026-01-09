# frozen_string_literal: true

module BulkActions
  # A super class for bulk jobs that take a druids as input and support closing versions.
  class ClosingBulkActionJob < BulkActions::BulkActionJob
    def perform(bulk_action:, druids:, close_version:, **params)
      @close_version = close_version
      super
    end

    def close_version?
      @close_version
    end
  end
end
