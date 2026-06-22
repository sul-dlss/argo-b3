# frozen_string_literal: true

module BulkActions
  # A job that, given a list of druids, generates a PDF tracking sheet for each object
  # and writes the results to a single PDF file for download.
  class ExportTrackingSheetsJob < DruidsJob
    def perform_bulk_action
      pdf = TracksheetService.call(solr_doc_presenters:)
      pdf.render_file(bulk_action.export_filepath)
    rescue StandardError => e
      log("ExportTrackingSheetsJob failed #{e.class} #{e.message}")
      Honeybadger.notify(e)
    end

    private

    def solr_doc_presenters
      druids.filter_map do |druid|
        SolrDocPresenter.new(solr_doc: Sdr::Repository.find_solr(druid:)).tap do
          success!(druid:, message: 'Fetched Solr document for tracking sheet')
        end
      rescue Sdr::Repository::NotFoundResponse => e
        failure!(druid:, message: "Solr document not found: #{e.message}")
        nil
      end
    end
  end
end
