# frozen_string_literal: true

require 'csv'

module BulkActions
  # Superclass of bulk action jobs that register new objects.
  # Subclasses must implement the `#registrations` method and provide a nested `JobItem` class
  # that is a subclass of BaseRegisterJobItem.
  class BaseRegisterJob < BaseJob
    HEADERS = ['Druid', 'Barcode', 'Folio Instance HRID', 'Source Id', 'Title'].freeze

    def perform_bulk_action
      registration_report_filepath = bulk_action.export_filepath(:registration_report)
      CSV.open(registration_report_filepath, 'wb', write_headers: true, headers: HEADERS) do |registration_report_csv|
        registrations.each.with_index(index_offset) do |registration, index|
          perform_item_class.new(index:, job: self, registration:, registration_report_csv:).perform
        rescue StandardError => e
          failure!(message: "Error: #{e.class} #{e.message}", index:)
        end
      end
    end

    # Subclasses must implement.
    # @return [Enumerable] one entry for each object to be registered
    def registrations
      raise NotImplementedError
    end

    # Offset for the line number that is logged for each registration.
    # Subclasses that read from a CSV should override with 2, since the header is line 1.
    def index_offset
      1
    end

    # Note that unlike other bulk action jobs, the druid is optional since it does not exist
    # until the object has been registered.
    def success!(message:, index:, druid: nil)
      bulk_action.increment(:druid_count_success).save
      log(delimited_log_message(message:, index:, druid:))
    end

    def failure!(message:, index:, druid: nil)
      bulk_action.increment(:druid_count_fail).save
      log(delimited_log_message(message:, index:, druid:))
    end

    def druid_count
      registrations.length
    end
  end
end
