# frozen_string_literal: true

module BulkActions
  # Form object for import structural metadata bulk action.
  # Only the headers are validated here; the rows are validated per object by the job.
  class ImportStructuralMetadataForm < BasicCsvForm
    private

    def validate_normalized_csv
      validator = CsvUpload::Validator.new(csv: normalized_csv_file,
                                           required_headers: StructuralCsv::Validator::REQUIRED_COLUMNS)
      return if validator.valid?

      validator.errors.each do |message|
        errors.add(:csv_file, :invalid, message:)
      end
    end
  end
end
