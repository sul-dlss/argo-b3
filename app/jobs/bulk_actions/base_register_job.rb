# frozen_string_literal: true

require 'csv'

module BulkActions
  # Superclass of bulk action jobs that register new objects, creating a registration report and tracking sheets.
  # Subclasses must implement the `#registrations` method and provide a nested `JobItem` class
  # that is a subclass of BaseRegisterJobItem.
  class BaseRegisterJob < BaseJob
    HEADERS = ['Druid', 'Barcode', 'Folio Instance HRID', 'Source Id', 'Title'].freeze

    def perform_bulk_action
      registered_druids = register_objects

      write_tracking_sheets(registered_druids:) if registered_druids.any?
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

    private

    # Registers each object, writing the registration report.
    # @return [Array<String>] druids of the registered objects, in registration order
    def register_objects
      registration_report_filepath = bulk_action.export_filepath(:registration_report)
      CSV.open(registration_report_filepath, 'wb', write_headers: true, headers: HEADERS) do |registration_report_csv|
        registrations.each.with_index(index_offset).filter_map do |registration, index|
          job_item = perform_item_class.new(index:, job: self, registration:, registration_report_csv:)
          job_item.perform
          # The druid is only set once the object has been registered.
          job_item.druid
        rescue StandardError => e
          failure!(message: "Error: #{e.class} #{e.message}", index:)
          nil
        end
      end
    end

    # Failing to create the tracking sheets does not fail the registrations.
    def write_tracking_sheets(registered_druids:)
      solr_doc_presenters = tracking_sheet_solr_doc_presenters(registered_druids:)
      return if solr_doc_presenters.empty?

      TracksheetService.call(solr_doc_presenters:).render_file(bulk_action.export_filepath(:tracking_sheets))
    rescue StandardError => e
      log("Error: Unable to create tracking sheets: #{e.class} #{e.message}")
      Honeybadger.notify(e)
    end

    def tracking_sheet_solr_doc_presenters(registered_druids:)
      registered_druids.filter_map do |druid|
        SolrDocPresenter.new(solr_doc: Sdr::Repository.find_solr(druid:))
      rescue StandardError => e
        log(delimited_log_message(message: "Error: Unable to create tracking sheet: #{e.class} #{e.message}", druid:))
        Honeybadger.notify(e)
        nil
      end
    end
  end
end
