# frozen_string_literal: true

module BulkActions
  # Form object for import structural metadata bulk action.
  # Only the headers are validated here; the rows are validated per object by the job.
  class ImportStructuralMetadataForm < BasicCsvForm
    validate :csv_file_must_be_valid

    private

    def csv_file_must_be_valid
      return if csv_file.blank?

      validator = CsvUpload::Validator.new(csv: normalized_csv_file,
                                           required_headers: StructuralCsv::Validator::REQUIRED_COLUMNS)
      return if validator.valid?

      validator.errors.each do |message|
        errors.add(:csv_file, :invalid, message:)
      end
    end
  end
end
