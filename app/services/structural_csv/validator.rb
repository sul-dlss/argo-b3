# frozen_string_literal: true

module StructuralCsv
  # Validates the structural metadata CSV rows for a single object, before any records are built.
  # See StructuralCsv::Import for the columns and how blank cells are handled.
  class Validator
    REQUIRED_COLUMNS = %w[druid sequence filename publish preserve rights_view rights_download rights_location].freeze

    def self.call(...)
      new(...).call
    end

    # @param rows [Array<Row>] the rows for a single object
    # @param content_file_binaries_by_filepath [Hash<String, ContentFileBinary>] the Content's binaries, with their
    #   ContentFiles loaded
    def initialize(rows:, content_file_binaries_by_filepath:)
      @all_rows = rows
      @content_file_binaries_by_filepath = content_file_binaries_by_filepath
      @errors = []
    end

    # Missing columns are reported alone, since the row checks would just be noise.
    # @return [Array<ValidationError>]
    def call
      validate_columns
      return errors if errors.any?

      validate_rows
      errors
    end

    private

    attr_reader :all_rows, :content_file_binaries_by_filepath, :errors

    def add_error(row, reason)
      errors << ValidationError.new(row.number, reason)
    end

    def headers
      all_rows.first&.headers || []
    end

    def column?(column)
      headers.include?(column)
    end

    # Entirely blank rows are dropped. A row with any value but a blank filename is an error.
    def rows
      @rows ||= all_rows.reject(&:entirely_blank?)
    end

    # Validates that every required column is present in the headers.
    def validate_columns
      (REQUIRED_COLUMNS - headers).each do |column|
        errors << ValidationError.new(1, "Missing required column \"#{column}\"")
      end
    end

    # Validates that there is at least one (non-blank) row, since an import cannot empty an object's structure,
    # and then validates each row individually and the rows collectively (mimetypes and sequence groups).
    def validate_rows
      return errors << ValidationError.new(all_rows.first&.number, 'No files to import') if rows.empty?

      rows.each { |row| validate_row(row) }
      validate_mimetypes
      validate_groups
    end

    # Validates the values of a single row.
    def validate_row(row)
      validate_sequence(row)
      validate_required_values(row)
      validate_required_booleans(row)
      validate_optional_booleans(row)
      validate_content_file_binary(row)
    end

    # Validates that the sequence is a positive integer (e.g., not blank, 0, 01, or 1.0).
    def validate_sequence(row)
      return if row.valid_sequence?

      add_error(row, "Sequence \"#{row.value('sequence')}\" is not a positive integer")
    end

    # Validates that cells that cannot be blank have a value: filename, rights_view, and rights_download, as well as
    # resource_type and mimetype when their (optional) columns are present.
    def validate_required_values(row)
      required_columns = %w[filename rights_view rights_download] +
                         %w[resource_type mimetype].select { |column| column?(column) }
      required_columns.each do |column|
        add_error(row, "Value for \"#{column}\" is missing") if row.blank?(column)
      end
    end

    # Validates that publish and preserve, as well as shelve when its (optional) column is present, are booleans
    # (yes, no, true, or false). A blank cell is not allowed.
    def validate_required_booleans(row)
      required_columns = %w[publish preserve] + %w[shelve].select { |column| column?(column) }
      required_columns.each do |column|
        add_error(row, boolean_error(row, column)) unless row.boolean?(column)
      end
    end

    # Validates that sdr_generated_text and corrected_for_accessibility, when their columns are present, are booleans
    # (yes, no, true, or false). A blank cell is allowed (and is false).
    def validate_optional_booleans(row)
      %w[sdr_generated_text corrected_for_accessibility].select { |column| column?(column) }.each do |column|
        next if row.blank?(column) || row.boolean?(column)

        add_error(row, boolean_error(row, column))
      end
    end

    def boolean_error(row, column)
      "Value for \"#{column}\" (\"#{row.value(column)}\") must be yes, no, true, or false"
    end

    # Validates that the filename matches an existing ContentFileBinary (since files cannot be added), and if so,
    # that its preserve value is allowed.
    def validate_content_file_binary(row)
      return if row.blank?('filename')

      content_file_binary = content_file_binaries_by_filepath[row.filename]
      if content_file_binary.nil?
        add_error(row, "#{row.filename} is not an existing file (files cannot be added)")
      else
        validate_preserve(row:, content_file_binary:)
      end
    end

    # Validates that a deposited file that is not preserved is not changed to preserved, based on the binary's first
    # existing ContentFile.
    def validate_preserve(row:, content_file_binary:)
      return unless row.boolean('preserve') && content_file_binary.file_location_deposited?
      return unless content_file_binary.content_files.min_by(&:id)&.preserve == false

      add_error(row, "#{row.filename} cannot be changed from preserve=no to preserve=yes")
    end

    # Validates that every row with the same filename has the same mimetype, since the mime type is stored on the
    # binary and so is shared by every file that references it.
    def validate_mimetypes
      return unless column?('mimetype')

      mimetypes_by_filename = {}
      rows.each do |row|
        next if row.blank?('filename') || row.blank?('mimetype')

        mimetype = mimetypes_by_filename[row.filename] ||= row.value('mimetype')
        next if mimetype == row.value('mimetype')

        add_error(row, "#{row.filename} has different mimetypes (\"#{mimetype}\" and \"#{row.value('mimetype')}\")")
      end
    end

    # Validates that the rows for each sequence are together (contiguous), reporting the row where a sequence
    # reappears, and validates each group of rows.
    def validate_groups
      seen_sequences = Set.new
      Row.groups(rows).each do |group|
        unless seen_sequences.add?(group.first.sequence)
          add_error(group.first, "Rows for sequence #{group.first.sequence} must be together")
        end
        validate_group_consistency(group)
        validate_group_filenames(group)
      end
    end

    # Validates that resource_label and resource_type (when their columns are present) are the same for every row in
    # a group, since they are values of the file set.
    def validate_group_consistency(group)
      %w[resource_label resource_type].select { |column| column?(column) }.each do |column|
        group.drop(1).each do |row|
          next if row.value(column) == group.first.value(column)

          add_error(row, "Value for \"#{column}\" must be the same for every row with sequence #{row.sequence}")
        end
      end
    end

    # Validates that a filename appears at most once in a group. The same filename in different groups is allowed
    # (multiple ContentFiles referencing the same binary).
    def validate_group_filenames(group)
      seen_filenames = Set.new
      group.each do |row|
        next if row.blank?('filename') || seen_filenames.add?(row.filename)

        add_error(row, "#{row.filename} appears more than once for sequence #{row.sequence}")
      end
    end
  end
end
