# frozen_string_literal: true

module BulkActions
  # Job to validate descriptive metadata from a CSV file without applying changes
  class ValidateDescriptiveMetadataJob < BaseCsvJob
    # Validate descriptive metadata from single CSV row
    class JobItem < BaseCsvJobItem
      def perform # rubocop:disable Metrics/AbcSize
        # Validating is typically a dry run before import; check the same permission as import,
        # to avoid the confusing situation where a spreadsheet could pass validation but fail
        # to import when a user can read but not update an object.
        return unless check_update_ability?

        import_result = DescriptiveCsv::Import.import(csv_row: row, druid: cocina_object.externalIdentifier)
        return failure!(message: import_result.failure.to_sentence) if import_result.failure?

        description = import_result.value!

        validate_result = CocinaSupport.validate(cocina_object, description:)
        return failure!(message: "Validation failed (#{validate_result.failure})") if validate_result.failure?

        Dor::Services::Client.objects.indexable(druid: cocina_object.externalIdentifier,
                                                cocina: cocina_object.new(description:))

        success!(message: 'Successfully validated')
      rescue Dor::Services::Client::UnprocessableContentError => e
        failure!(message: "indexing validation failed for #{cocina_object.externalIdentifier}: #{e.message}")
      end
    end
  end
end
