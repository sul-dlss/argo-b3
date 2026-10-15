# frozen_string_literal: true

module BulkActions
  # Form object for import read restricted and edit permissions bulk action.
  class ImportReadRestrictedAndEditPermissionsForm < BasicCsvForm
    REQUIRED_HEADERS = %w[permission_type druid workgroup].freeze

    private

    def validate_csv_file
      validator = CsvUpload::Validator.new(csv: normalized_csv_file, required_headers: REQUIRED_HEADERS)
      return if validator.valid?

      validator.errors.each do |message|
        errors.add(:csv_file, :invalid, message:)
      end
    end
  end
end
