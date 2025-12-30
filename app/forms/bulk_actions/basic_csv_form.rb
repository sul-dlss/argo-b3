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

      csv = CSV.parse(normalized_csv_file, headers: true)
      validator = DescriptiveCsv::Validator.new(csv, bulk_job: true)
      return if validator.valid?

      validator.errors.each do |message|
        errors.add(:csv_file, :invalid, message:)
      end
    end
  end
end
