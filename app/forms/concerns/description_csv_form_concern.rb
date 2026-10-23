# frozen_string_literal: true

# Concern for forms whose description is imported from an uploaded description spreadsheet.
# The including form declares the validations (description_csv_must_be_valid requires a file)
# and provides description_hash.
module DescriptionCsvFormConcern
  extend ActiveSupport::Concern

  included do
    attribute :description_csv_file, :uploaded_file
  end

  private

  # Normalizes, validates, and imports the uploaded description spreadsheet. This is a validation rather
  # than a before_validation callback because a callback cannot add errors and the description must only
  # be imported when the spreadsheet has none.
  # Errors are reported for description_csv_file since that is the field the user provides.
  def description_csv_must_be_valid
    description_csv = parsed_description_csv
    validator = DescriptiveCsv::Validator.new(description_csv)
    return add_description_csv_errors(validator.errors) unless validator.valid?

    return unless description_csv_row_count_valid?(description_csv)

    populate_description_hash_from_csv_row(description_csv.first)
  rescue CsvUpload::Normalizer::Error => e
    errors.add(:description_csv_file, :invalid, message: e.message)
  end

  # A single item is described by a single row.
  def description_csv_row_count_valid?(description_csv)
    return true if description_csv.size == 1

    validation_key = description_csv.empty? ? 'no_rows' : 'extra_rows'
    errors.add(:description_csv_file,
               I18n.t("edit.items.fields.description_csv_file.validations.#{validation_key}"))
    false
  end

  # @return [CSV::Table]
  def parsed_description_csv
    CSV.parse(CsvUpload::Normalizer.read(description_csv_file.path), headers: true)
  end

  # An unregistered object has no druid, so its description has no purl.
  def populate_description_hash_from_csv_row(csv_row)
    import_result = DescriptiveCsv::Import.import(csv_row:, druid:)
    return add_description_csv_errors(import_result.failure) if import_result.failure?

    description = import_result.value!
    # DescriptiveCsv::Validator only checks that the spreadsheet has a title column, not that the column
    # has a value, and a RequestDescription (unlike a Description) allows an empty title.
    if description.title.empty?
      return errors.add(:description_csv_file,
                        I18n.t('edit.items.fields.description_csv_file.validations.missing_title'))
    end

    self.description_hash = description.to_h
  end

  def add_description_csv_errors(messages)
    messages.each { |message| errors.add(:description_csv_file, :invalid, message:) }
  end
end
