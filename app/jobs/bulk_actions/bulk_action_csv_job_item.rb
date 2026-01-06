# frozen_string_literal: true

module BulkActions
  # Super class for performing an action on a single row in a BulkActionCsvJob.
  # Subclasses must implement the perform method.
  class BulkActionCsvJobItem < BulkActionJobItem
    def initialize(row:, **args)
      @row = row
      Honeybadger.context(row:)
      super(**args)
    end

    attr_reader :row

    def success!(message:)
      job.success!(druid:, message:, index:)
    end

    def failure!(message:)
      job.failure!(druid:, message:, index:)
    end
  end
end
