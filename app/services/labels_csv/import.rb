# frozen_string_literal: true

module LabelsCsv
  # Updates the labels of a Content's resources from the labels CSV rows for a single object, without otherwise
  # changing the structure.
  #
  # The CSV has the following (required) headers:
  # - druid (validated by the caller)
  # - sequence (the position of an existing resource, starting at 1)
  # - resource_label (a blank cell clears the label)
  #
  # Resources without a row keep their labels, and rows whose sequence is past the last resource are ignored.
  # Entirely blank rows are ignored, but there must be at least one other row.
  class Import
    include Dry::Monads[:result]

    def self.call(...)
      new(...).call
    end

    # @param rows [Array<Array(Integer, CSV::Row)>] the rows for a single object, each paired with its spreadsheet
    #   row number (used in error messages)
    # @param content [Content] the mutable Content to update
    # @raise [ArgumentError] if the Content is immutable
    def initialize(rows:, content:)
      raise ArgumentError, 'Content must be mutable' if content.immutable?

      @rows = rows.map { |number, csv_row| StructuralCsv::Row.new(number:, csv_row:) }
      @content = content
    end

    # Nothing is saved unless the rows are all valid.
    # @return [Dry::Monads::Result] Success if the labels were updated, or Failure with an
    #   Array<StructuralCsv::ValidationError>
    def call
      errors = Validator.call(rows:)
      return Failure(errors) if errors.any?

      save
      Success()
    end

    private

    attr_reader :rows, :content

    def save
      labels_by_sequence = rows.reject(&:entirely_blank?).to_h { |row| [row.sequence, row.value('resource_label')] }
      ContentFileSet.transaction do
        content.content_file_sets.each.with_index(1) do |content_file_set, sequence|
          next unless labels_by_sequence.key?(sequence)

          content_file_set.update!(label: labels_by_sequence[sequence])
        end
      end
    end
  end
end
