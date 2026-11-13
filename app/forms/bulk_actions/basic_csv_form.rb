# frozen_string_literal: true

module BulkActions
  # Form object that only includes the basic attributes including a CSV file.
  # This can be used by itself or as a superclass for more complex forms.
  class BasicCsvForm < ApplicationForm
    attribute :csv_file, :uploaded_file
    validates :csv_file, presence: true
    validate :csv_file_must_be_valid

    attribute :description, :string

    # Only offered by bulk actions configured with close_version.
    attribute :close_version, :boolean, default: true

    # Subclasses may override; the controller adds close_version, if configured.
    # @return [Hash] the job parameters: the normalized CSV and the form's own attributes
    def job_params
      attributes.symbolize_keys.except(:csv_file, :description, :close_version).merge(csv_file: normalized_csv_file)
    end

    def normalized_csv_file
      @normalized_csv_file ||= CsvUpload::Normalizer.read(csv_file.path)
    end

    private

    def csv_file_must_be_valid
      return if csv_file.blank?

      # Read the file now so unreadable files are reported here; it is then memoized for future callers.
      normalized_csv_file
      validate_normalized_csv
    rescue CsvUpload::Normalizer::Error => e
      errors.add(:csv_file, :invalid, message: e.message)
    end

    # Subclasses may override to perform additional validations on the CSV file.
    # Only called once the CSV file has been successfully normalized.
    def validate_normalized_csv; end
  end
end
