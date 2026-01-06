# frozen_string_literal: true

module BulkActions
  # Form object for register bulk action.
  class RegisterForm < BasicCsvForm
    REQUIRED_HEADERS = %w[
      content_type
      administrative_policy_object
      source_id
      initial_workflow
      rights_view
      rights_download
    ].freeze

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
