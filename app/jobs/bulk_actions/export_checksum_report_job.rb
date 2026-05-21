# frozen_string_literal: true

module BulkActions
  # A job that, given a list of druids, fetches checksums from the preservation catalog
  # and writes the results to a CSV file for download.
  class ExportChecksumReportJob < DruidsJob
    HEADERS = %w[druid filename md5 sha1 sha256 size].freeze

    def export_file
      @export_file ||= CSV.open(bulk_action.export_filepath, 'w', write_headers: true, headers: HEADERS)
    end

    # Export checksums for a single object
    class JobItem < BaseJobItem
      def perform # rubocop:disable Metrics/AbcSize
        return unless check_read_ability?

        Preservation::Client.objects.checksum(druid:).each do |hash|
          export_file << [druid, hash['filename'], hash['md5'], hash['sha1'], hash['sha256'], hash['filesize']]
        end

        success!(message: 'Exported checksum report')
      rescue Preservation::Client::NotFoundError
        export_file << [druid, 'object not found or not fully accessioned']
        failure!(message: 'Object not found or not fully accessioned')
      end
    end
  end
end
