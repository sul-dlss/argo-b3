# frozen_string_literal: true

module StructuralCsv
  # Validates the structural metadata CSV rows for a single object, before any records are built.
  # See StructuralCsv::Import for the columns and how blank cells are handled.
  class Validator
    RIGHTS_COLUMNS = %w[rights_view rights_download rights_location].freeze
    REQUIRED_COLUMNS = (%w[druid sequence filename publish preserve] + RIGHTS_COLUMNS).freeze

    def self.call(...)
      new(...).call
    end

    # When the rights are optional, the rights columns may be left out together (so that each file gets the default
    # file access), and rights_location may be left out alone (as if every cell were blank).
    # @param headers [Array<String>] the CSV's headers
    # @param rights_optional [Boolean] whether the rights columns may be left out
    # @return [Array<String>] the columns that the CSV must have
    def self.required_columns(headers:, rights_optional: false)
      return REQUIRED_COLUMNS unless rights_optional
      return REQUIRED_COLUMNS - RIGHTS_COLUMNS unless headers.intersect?(RIGHTS_COLUMNS)

      REQUIRED_COLUMNS - ['rights_location']
    end

    # @param rows [Array<Row>] the rows for a single object
    # @param content_file_binaries_by_filepath [Hash<String, ContentFileBinary>] the Content's binaries
    # @param allow_file_deletion [Boolean] whether files omitted from the rows may be deleted
    # @param rights_optional [Boolean] whether the rights columns may be left out (see required_columns)
    def initialize(rows:, content_file_binaries_by_filepath:, allow_file_deletion: true, rights_optional: false)
      @all_rows = rows
      @content_file_binaries_by_filepath = content_file_binaries_by_filepath
      @allow_file_deletion = allow_file_deletion
      @rights_optional = rights_optional
      @errors = []
    end

    # Missing columns are reported alone, since the row checks would just be noise. Otherwise, every problem is
    # reported, so that the CSV can be fixed in one pass, by row number and with errors that are not for a row last.
    # @return [Array<ValidationError>]
    def call
      validate_columns
      return errors if errors.any?

      validate_rows
      errors.sort_by.with_index { |error, index| [error.line_number ? 0 : 1, error.line_number.to_i, index] }
    end

    private

    attr_reader :all_rows, :content_file_binaries_by_filepath, :allow_file_deletion, :rights_optional, :errors

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
      (self.class.required_columns(headers:, rights_optional:) - headers).each do |column|
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
      validate_file_deletion
    end

    # Validates the values of a single row. A value is reported once: when it is missing or not allowed, the checks
    # that depend on it (e.g., the combination of access rights) are skipped.
    def validate_row(row)
      validate_sequence(row)
      validate_required_values(row)
      validate_required_booleans(row)
      validate_optional_booleans(row)
      validate_content_file_binary(row)
      validate_resource_type(row)
      validate_access(row)
      validate_shelve(row)
    end

    # Validates that resource_type (when its column is present and the cell has a value) is a file set type.
    def validate_resource_type(row)
      return if !column?('resource_type') || row.blank?('resource_type') || valid_resource_type?(row)

      add_error(row, "Value for \"resource_type\" (\"#{row.value('resource_type')}\") is not a valid resource type")
    end

    # Without the rights columns, the files get the default file access, so there is nothing to validate.
    def validate_access(row)
      return unless column?('rights_view')

      AccessValidator.call(row:).each { |reason| add_error(row, reason) }
    end

    # Validates that a shelved file is published or preserved. Without a shelve column, shelve follows publish.
    def validate_shelve(row)
      return unless column?('shelve')
      return unless %w[shelve publish preserve].all? { |column| row.boolean?(column) }
      return unless row.boolean('shelve') && !row.boolean('publish') && !row.boolean('preserve')

      add_error(row, "Value for \"shelve\" (\"#{row.value('shelve')}\") requires publish or preserve")
    end

    # Validates that the sequence is a positive integer (e.g., not blank, 0, 01, or 1.0).
    def validate_sequence(row)
      return if row.valid_sequence?

      add_error(row, "Sequence \"#{row.value('sequence')}\" is not a positive integer")
    end

    # Validates that cells that cannot be blank have a value: filename, as well as rights_view, rights_download,
    # resource_type, and mimetype when their columns are present.
    def validate_required_values(row)
      required_columns = %w[filename] +
                         %w[rights_view rights_download resource_type mimetype].select { |column| column?(column) }
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

    # Validates that the filename matches an existing ContentFileBinary (since files cannot be added).
    def validate_content_file_binary(row)
      return if row.blank?('filename')
      return if content_file_binaries_by_filepath.key?(row.filename)

      add_error(row, "#{row.filename} is not an existing file (files cannot be added)")
    end

    # Validates that no file would be deleted (by being omitted from every row) unless deletion is allowed.
    # The error is not for a row, so it has no line number.
    def validate_file_deletion
      return if allow_file_deletion

      deleted_filepaths = content_file_binaries_by_filepath.keys - rows.map(&:filename)
      return if deleted_filepaths.empty?

      errors << ValidationError.new(nil, "Files would be deleted: #{deleted_filepaths.sort.join(', ')}. " \
                                         'Select "Allow files to be deleted" to delete them.')
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
    # a group, since they are values of the file set. A resource type that is missing or not allowed is already
    # reported, so it is not compared.
    def validate_group_consistency(group)
      %w[resource_label resource_type].select { |column| column?(column) }.each do |column|
        compared_rows = column == 'resource_type' ? group.select { |row| valid_resource_type?(row) } : group
        compared_rows.drop(1).each do |row|
          next if row.value(column) == compared_rows.first.value(column)

          add_error(row, "Value for \"#{column}\" must be the same for every row with sequence #{row.sequence}")
        end
      end
    end

    def valid_resource_type?(row)
      FileSetTypes::ALL.include?(row.value('resource_type'))
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
