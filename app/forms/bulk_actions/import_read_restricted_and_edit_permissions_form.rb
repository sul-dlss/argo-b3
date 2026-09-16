# frozen_string_literal: true

module BulkActions
  # Form object for import read restricted and edit permissions bulk action.
  class ImportReadRestrictedAndEditPermissionsForm < BasicCsvForm
    REQUIRED_HEADERS = %w[permission_type druid workgroup].freeze

    validate :csv_file_must_be_valid

    private

    def csv_file_must_be_valid
      return if csv_file.blank?

      validator = CsvUpload::Validator.new(csv: normalized_csv_file, required_headers: REQUIRED_HEADERS)
      return if validator.valid?

      validator.errors.each do |message|
        errors.add(:csv_file, :invalid, message:)
      end
    end
  end
end
