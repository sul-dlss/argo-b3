# frozen_string_literal: true

module BulkActions
  # Form object for import catalog data bulk action.
  class ImportCatalogDataForm < BasicCsvForm
    REQUIRED_HEADERS = %w[druid].freeze

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
