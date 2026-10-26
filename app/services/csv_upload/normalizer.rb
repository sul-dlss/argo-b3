# frozen_string_literal: true

module CsvUpload
  # Reads and normalizes a CSV that is uploaded as part of Bulk Actions.
  class Normalizer
    # Raised when the uploaded file cannot be read, e.g., unsupported file type, encoding error, or malformed CSV.
    class Error < StandardError; end

    # Note that .xls is not supported because roo-xls has not been updated for roo 3.x (see Gemfile).
    SUPPORTED_FILE_EXTENSIONS = %w[.csv .ods .xlsx].freeze

    def self.read(...)
      new(...).read
    end

    # @param path [String] path to uploaded file
    # @param headers [Boolean] whether the first row is a header row. Without headers, rows are not aligned to
    #   columns, so blank cells are removed (and druids are not normalized, since there is no druid column).
    def initialize(path, headers: true)
      @path = path
      @headers = headers
    end

    # Reads uploaded file (could be csv or Excel) and normalizes to CSV.
    # This includes handling BOM and druids without prefixes.
    # @return [String] csv
    # @raise [Error] if unsupported file type or the file cannot be read, e.g., invalid byte sequence, malformed CSV,
    #   or permission denied
    def read # rubocop:disable Metrics/AbcSize
      raise Error, 'Unsupported upload file type' unless normalized_file_extension.in?(SUPPORTED_FILE_EXTENSIONS)

      # If handed *anything but* a CSV file, first pre-process into a CSV string with Roo.
      csv_string = normalized_file_extension == '.csv' ? normalized_csv_string : Roo::Spreadsheet.open(path).to_csv

      headers ? normalize_with_headers(csv_string) : normalize_without_headers(csv_string)
    rescue CSV::MalformedCSVError => e
      raise Error, e.message
    rescue Zip::Error => e
      raise Error, "Spreadsheet could not be opened: #{e.message}"
    rescue SystemCallError => e
      raise Error, "File could not be read: #{e.message}"
    end

    private

    attr_reader :path, :headers

    # Deal with both pre-processed CSV strings or files, using the built-in CSV
    # library to parse either.
    def parse(csv_string)
      CSV.parse(csv_string, headers:, skip_blanks: true, skip_lines: /^\s*$/, converters: whitespace_only_nullifier)
    end

    def normalize_with_headers(csv_string) # rubocop:disable Metrics/AbcSize
      parse(csv_string).tap do |csv|
        # Remove rows that are a bunch of nils
        csv.by_row!.delete_if { |row| row.fields.none? }

        # Remove columns that lack a header (e.g., if the header row winds up with
        # any repeated commas in it)
        csv.by_col!.delete_if { |(column, *)| column.nil? }

        # Normalize the druids in the druid column, if present, to have the 'druid:' prefix
        csv.headers.find { |header| header.match?(/\Adruid\z/i) }.tap do |druid_column|
          next if druid_column.nil?

          csv[druid_column] = csv[druid_column].map { |druid| DruidSupport.prefixed_druid_from(druid) }
        end
      end.to_csv
    end

    def normalize_without_headers(csv_string)
      parse(csv_string).map(&:compact).reject(&:empty?).map(&:to_csv).join
    end

    def normalized_file_extension
      @normalized_file_extension ||= File.extname(path).downcase
    end

    # This method:
    #
    # 1. Removes the BOM if present (since CSV.parse will not)
    # 2. Ignores any preamble lines before the legitimate header row (if there are headers)
    # 3. Removes line feeds at the end of lines (`CSV#parse` wants newlines)
    def normalized_csv_string
      csv = File.read(path, encoding: 'bom|utf-8')
      validate_encoding!(csv)
      lines = csv.split(/\r?\n/)
      return lines.join("\n") unless headers

      lines.shift until lines.first&.match?(/\Adruid,/i) || lines.empty?
      return csv if lines.empty?

      lines.join("\n")
    end

    def validate_encoding!(csv)
      return if csv.valid_encoding?

      # Check physical lines before normalization changes their numbers or CSV parsing touches the invalid bytes.
      line_number = csv.each_line.with_index(1).find { |line, _number| !line.valid_encoding? }.last
      raise Error, "CSV contains invalid UTF-8 bytes on line #{line_number}."
    end

    def whitespace_only_nullifier
      ->(field) { field&.strip.presence }
    end
  end
end
