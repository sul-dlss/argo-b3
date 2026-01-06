# frozen_string_literal: true

module BulkActions
  # A super class for bulk jobs that take a CSV file as input and support closing versions.
  class ClosingBulkActionCsvJob < BulkActionCsvJob
    def perform(bulk_action:, csv_file:, close_version:, **params)
      @close_version = close_version
      super
    end

    def close_version?
      @close_version
    end
  end
end
