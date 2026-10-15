# frozen_string_literal: true

module BulkActions
  # Form object that only includes the basic attributes including a CSV file.
  # This can be used by itself or as a superclass for more complex forms.
  class BasicCsvForm < ApplicationForm
    attribute :csv_file, :uploaded_file
    validates :csv_file, presence: true
    validate :csv_file_must_be_valid

    attribute :description, :string

    # Only applies to some bulk actions.
    # For those bulk actions, with_close_version to true for BulkActions::FormComponent.
    attribute :close_version, :boolean, default: true

    def normalized_csv_file
      @normalized_csv_file ||= CsvUpload::Normalizer.read(csv_file.path)
    end

    private

    def csv_file_must_be_valid
      return if csv_file.blank?

      normalized_csv_file
      validate_csv_file
    rescue CsvUpload::Normalizer::Error => e
      errors.add(:csv_file, :invalid, message: e.message)
    end

    # Subclasses may override to perform additional validations on the CSV file.
    def validate_csv_file; end
  end
end
