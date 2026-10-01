# frozen_string_literal: true

module StructuralCsv
  # A row of a structural metadata CSV, paired with its spreadsheet row number.
  # Cell values are stripped, with blank cells as ''.
  class Row
    BOOLEAN_VALUES = { 'yes' => true, 'true' => true, 'no' => false, 'false' => false }.freeze

    # Consecutive rows with the same (valid) sequence. Once rows are validated, each sequence has a single group.
    # @param rows [Array<Row>]
    # @return [Array<Array<Row>>]
    def self.groups(rows)
      rows.select(&:valid_sequence?).chunk_while { |row, next_row| row.sequence == next_row.sequence }.to_a
    end

    # @param number [Integer] the spreadsheet row number
    # @param csv_row [CSV::Row]
    def initialize(number:, csv_row:)
      @number = number
      @csv_row = csv_row
    end

    attr_reader :number

    delegate :headers, to: :csv_row

    def present?(column)
      headers.include?(column)
    end

    def value(column)
      csv_row[column].to_s.strip
    end

    def blank?(column)
      value(column).empty?
    end

    # @return [String] the value if the column is present (even if blank), otherwise the block's value
    def fetch(column)
      present?(column) ? value(column) : yield
    end

    # @return [Boolean, nil] nil if the cell is not a boolean
    def boolean(column)
      BOOLEAN_VALUES[value(column).downcase]
    end

    def boolean?(column)
      BOOLEAN_VALUES.key?(value(column).downcase)
    end

    # @return [Boolean, nil] the boolean if the column is present (nil if not a boolean), otherwise the block's value
    def fetch_boolean(column)
      present?(column) ? boolean(column) : yield
    end

    def filename
      value('filename')
    end

    def valid_sequence?
      value('sequence').match?(/\A[1-9]\d*\z/)
    end

    def sequence
      value('sequence').to_i
    end

    def location_based?
      [value('rights_view'), value('rights_download')].include?('location-based')
    end

    # The druid is ignored, since rows are grouped by druid.
    def entirely_blank?
      (headers - ['druid']).all? { |column| blank?(column) }
    end

    private

    attr_reader :csv_row
  end
end
