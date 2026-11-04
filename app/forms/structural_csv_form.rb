# frozen_string_literal: true

# Form for updating structural metadata via CSV upload.
# Only the upload is validated here (that it is present and readable); the rows are validated by StructuralCsv::Import.
class StructuralCsvForm < ApplicationForm
  attribute :csv_file, :uploaded_file
  validates :csv_file, presence: true
  validate :csv_file_must_be_readable

  # Whether files omitted from the CSV may be deleted.
  attribute :allow_file_deletion, :boolean, default: false

  # Each row paired with its spreadsheet row number (the header is row 1).
  # @return [Array<Array(Integer, CSV::Row)>]
  # @raise [CsvUpload::Normalizer::Error] if the file cannot be read
  def numbered_rows
    @numbered_rows ||= CSV.parse(CsvUpload::Normalizer.read(csv_file.path), headers: true)
                          .each.with_index(2).map { |row, row_number| [row_number, row] }
  end

  # @param content [Content] the mutable Content to update
  # @return [Dry::Monads::Result] see StructuralCsv::Import
  def import(content:)
    StructuralCsv::Import.call(rows: numbered_rows, content:, allow_file_deletion:)
  end

  # @param validation_errors [Array<StructuralCsv::ValidationError>]
  def add_validation_errors(validation_errors)
    validation_errors.each do |validation_error|
      message = validation_error.reason
      message = "Row #{validation_error.line_number}: #{message}" if validation_error.line_number
      errors.add(:csv_file, :invalid, message:)
    end
  end

  private

  def csv_file_must_be_readable
    return if csv_file.blank?

    numbered_rows
  rescue CsvUpload::Normalizer::Error => e
    errors.add(:csv_file, :invalid, message: e.message)
  end
end
