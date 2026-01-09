# frozen_string_literal: true

module BulkActions
  # Form object for import descriptive metadata bulk action.
  class ImportDescriptiveMetadataForm < BasicCsvForm
    validate :csv_file_must_be_valid

    private

    def csv_file_must_be_valid
      return if csv_file.blank?

      csv = CSV.parse(normalized_csv_file, headers: true)
      validator = DescriptiveCsv::Validator.new(csv, bulk_job: true)
      return if validator.valid?

      validator.errors.each do |message|
        errors.add(:csv_file, :invalid, message:)
      end
    end
  end
end
