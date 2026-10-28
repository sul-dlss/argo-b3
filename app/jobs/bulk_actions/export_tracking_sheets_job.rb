# frozen_string_literal: true

module BulkActions
  # A job that, given a list of druids, generates a PDF tracking sheet for each object
  # and writes the results to a single PDF file for download.
  class ExportTrackingSheetsJob < DruidsJob
    def perform_bulk_action
      pdf = TracksheetService.call(solr_doc_presenters:)
      pdf.render_file(bulk_action.export_filepath(:tracking_sheets))
    rescue StandardError => e
      log("ExportTrackingSheetsJob failed #{e.class} #{e.message}")
      Rails.logger.error(e.full_message)
      Honeybadger.notify(e)
    end

    private

    def solr_doc_presenters
      druids.filter_map do |druid|
        solr_doc = Sdr::Repository.find_solr(druid:)
        unless read_allowed?(solr_doc)
          failure!(druid:, message: 'Not authorized to read')
          next
        end

        SolrDocPresenter.new(solr_doc:).tap do
          success!(druid:, message: 'Fetched Solr document for tracking sheet')
        end
      rescue Sdr::Repository::NotFoundResponse => e
        failure!(druid:, message: "Solr document not found: #{e.message}")
        nil
      end
    end

    def read_allowed?(solr_doc)
      allowed_to?(:show?, solr_doc, with: ObjectPolicy, context: { user: })
    end
  end
end
