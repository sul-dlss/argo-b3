# frozen_string_literal: true

module BulkActions
  # Job to import descriptive metadata from a CSV file
  class ImportDescriptiveMetadataJob < BulkActions::ClosingBulkActionCsvJob
    # Import descriptive metadata from single CSV row
    class ImportDescriptiveMetadataJobItem < BulkActions::BulkActionCsvJobItem
      # Job to import descriptive metadata from single CSV row
      def perform # rubocop:disable Metrics/AbcSize
        return unless check_update_ability?

        import_result = DescriptiveCsv::Import.import(csv_row: row)
        return failure!(message: import_result.failure.to_sentence) if import_result.failure?

        description = import_result.value!

        # validates input data from spreadsheet before any updates are applied to provide error messages to the user
        validate_result = CocinaSupport.validate(cocina_object, description:)
        return failure!(message: "Validation failed (#{validate_result.failure})") if validate_result.failure?

        Dor::Services::Client.objects.indexable(druid: cocina_object.externalIdentifier,
                                                cocina: cocina_object.new(description:))

        return failure!(message: 'Description unchanged') if cocina_object.description == description

        open_new_version_if_needed!(description: 'Updated descriptive metadata')

        @cocina_object = cocina_object.new(description:)
        Sdr::Repository.store(cocina_object:)

        close_version_if_needed!
        success!(message: 'Successfully updated')
      rescue Dor::Services::Client::UnprocessableContentError => e
        failure!(message: "indexing validation failed for #{cocina_object.externalIdentifier}: #{e.message}")
      end
    end
  end
end
