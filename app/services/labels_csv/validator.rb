# frozen_string_literal: true

module LabelsCsv
  # Validates the labels CSV rows for a single object, before any labels are updated.
  # The druids are validated by the caller (see SingleObjectCsvUploadConcern).
  class Validator
    REQUIRED_COLUMNS = %w[druid sequence resource_label].freeze

    def self.call(...)
      new(...).call
    end

    # @param rows [Array<StructuralCsv::Row>] the rows for a single object
    # @param headers [Array<String>] the CSV's headers (which a CSV without any rows still has)
    def initialize(rows:, headers:)
      @all_rows = rows
      @headers = headers
      @errors = []
    end

    # Missing columns are reported alone, since the row checks would just be noise.
    # @return [Array<StructuralCsv::ValidationError>]
    def call
      validate_columns
      return errors if errors.any?
      return [StructuralCsv::ValidationError.new(all_rows.first&.number, 'No labels to import')] if rows.empty?

      validate_sequences
      errors
    end

    private

    attr_reader :all_rows, :headers, :errors

    # Entirely blank rows are ignored.
    def rows
      @rows ||= all_rows.reject(&:entirely_blank?)
    end

    def validate_columns
      (REQUIRED_COLUMNS - headers).each do |column|
        errors << StructuralCsv::ValidationError.new(1, "Missing required column \"#{column}\"")
      end
    end

    # Validates that each sequence is a positive integer (e.g., not blank, 0, 01, or 1.0) and appears only once,
    # since a resource can have only one label.
    def validate_sequences
      seen_sequences = Set.new
      rows.each do |row|
        if !row.valid_sequence?
          add_error(row, "Sequence \"#{row.value('sequence')}\" is not a positive integer")
        elsif !seen_sequences.add?(row.sequence)
          add_error(row, "Sequence #{row.sequence} appears more than once")
        end
      end
    end

    def add_error(row, reason)
      errors << StructuralCsv::ValidationError.new(row.number, reason)
    end
  end
end
