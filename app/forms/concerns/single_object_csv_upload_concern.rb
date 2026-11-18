# frozen_string_literal: true

# Concern for a form that uploads a CSV for one object (e.g., a structural or labels CSV in manage files).
# Only the upload is validated here (that it is present and readable) and the druids of its rows; the including
# form's import(content:) validates the rest of the rows and updates the Content, returning a Dry::Monads::Result
# whose Failure is an Array<StructuralCsv::ValidationError>.
module SingleObjectCsvUploadConcern
  extend ActiveSupport::Concern

  included do
    attribute :csv_file, :uploaded_file
    validates :csv_file, presence: true
    validate :csv_file_must_be_readable
  end

  # Each row paired with its spreadsheet row number (the header is row 1).
  # @return [Array<Array(Integer, CSV::Row)>]
  # @raise [CsvUpload::Normalizer::Error] if the file cannot be read
  def numbered_rows
    @numbered_rows ||= csv_table.each.with_index(2).map { |row, row_number| [row_number, row] }
  end

  # The headers, which a CSV without any rows still has.
  # @return [Array<String>]
  # @raise [CsvUpload::Normalizer::Error] if the file cannot be read
  def csv_headers
    csv_table.headers
  end

  # Updates an object's content from the uploaded CSV. Nothing is changed unless the upload and every row are valid;
  # otherwise, the errors are added (see errors).
  # @param content [Content] the mutable Content to update
  def update_content(content:)
    return unless valid?

    validation_errors = druid_errors(druid: content.druid)
    validation_errors = Array(import(content:).failure) if validation_errors.empty?
    add_validation_errors(validation_errors)
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

  def csv_table
    @csv_table ||= CSV.parse(CsvUpload::Normalizer.read(csv_file.path), headers: true)
  end

  # Since the CSV is for one object, every row must have its druid (rather than being grouped by druid, as by the
  # bulk action). The druids have already been prefixed by CsvUpload::Normalizer.
  # A missing druid column is reported by the including form's import.
  # @return [Array<StructuralCsv::ValidationError>]
  def druid_errors(druid:)
    numbered_rows.filter_map do |row_number, row|
      next unless row.headers.include?('druid')

      row_druid = row['druid'].to_s.strip
      next if row_druid == druid

      reason = row_druid.empty? ? 'Missing druid' : "Druid #{row_druid} does not match this object"
      StructuralCsv::ValidationError.new(row_number, reason)
    end
  end

  def csv_file_must_be_readable
    return if csv_file.blank?

    numbered_rows
  rescue CsvUpload::Normalizer::Error => e
    errors.add(:csv_file, :invalid, message: e.message)
  end
end
