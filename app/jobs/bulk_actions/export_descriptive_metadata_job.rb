# frozen_string_literal: true

module BulkActions
  # Export a spreadsheet of descriptive metadata
  class ExportDescriptiveMetadataJob < Job
    def perform_bulk_action
      grouped_descriptions = DescriptiveCsv::DescriptionsGrouper.group(descriptions:)
      ordered_headers = DescriptiveCsv::Headers.create(headers: grouped_descriptions.values.flat_map(&:keys).uniq)

      log('Writing to file')

      CSV.open(bulk_action.export_filepath, 'w', write_headers: true, headers: %w[druid] + ordered_headers) do |csv|
        grouped_descriptions.each do |druid, description|
          csv << ([druid] + description.values_at(*ordered_headers))
        end
      end
    end

    private

    def descriptions
      # NOTE: This could potentially consume a lot of memory, because we don't know which columns a record has ahead
      # of time, so we have to load all the records into memory first.
      @descriptions ||= druids.each_with_object({}) do |druid, out|
        item = Sdr::Repository.find(druid:)
        description = DescriptiveCsv::Export.export(source_id: item.identification.sourceId,
                                                    description: item.description)
        out[druid] = description
        success!(druid:)
      rescue Dor::Services::Client::BadRequestError, URI::InvalidURIError
        failure!(druid:, message: 'Could not request object')
      rescue Sdr::Repository::NotFoundResponse
        failure!(druid:, message: 'Could not find object')
      rescue Dor::Services::Client::UnexpectedResponse, NoMethodError => e
        failure!(druid:, message: "Failed #{e.class} #{e.message}")
      end
    end
  end
end
