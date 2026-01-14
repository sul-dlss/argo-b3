# frozen_string_literal: true

module BulkActions
  # Superclass for performing an action on a single row in a bulk action job.
  # Subclasses must implement the `#perform` method.
  class BaseCsvJobItem < BaseJobItem
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
