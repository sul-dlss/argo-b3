# frozen_string_literal: true

module BulkActions
  # Export a spreadsheet of descriptive metadata
  class ExportDescriptiveMetadataJob < DruidsJob
    def perform_bulk_action
      csv = DescriptiveCsv::Export.as_csv(descriptions:)

      log('Writing to file')

      File.write(bulk_action.export_filepath(:descriptive_metadata), csv)
    end

    private

    def descriptions
      # NOTE: This could potentially consume a lot of memory, because we don't know which columns a record has ahead
      # of time, so we have to load all the records into memory first.
      @descriptions ||= druids.each_with_object({}) do |druid, out|
        item = Sdr::Repository.find(druid:)
        next failure!(druid:, message: 'Not authorized to read') unless read_allowed?(item)

        out[druid] = export_description(item)
        success!(druid:)
      rescue Dor::Services::Client::BadRequestError, URI::InvalidURIError
        failure!(druid:, message: 'Could not request object')
      rescue Sdr::Repository::NotFoundResponse
        failure!(druid:, message: 'Could not find object')
      rescue Dor::Services::Client::UnexpectedResponse, NoMethodError => e
        failure!(druid:, message: "Failed #{e.class} #{e.message}")
      end
    end

    def export_description(item)
      DescriptiveCsv::Export.export(source_id: item.identification.sourceId, description: item.description)
    end

    def read_allowed?(item)
      allowed_to?(:show?, item, with: ObjectPolicy)
    end
  end
end
