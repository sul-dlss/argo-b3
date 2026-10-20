# frozen_string_literal: true

module ManifestCsv
  # Validates a multi-item deposit manifest, which maps each druid to its folder on the mount.
  class Validator
    DRUID_COLUMN = 'druid'
    FOLDER_NAME_COLUMN = 'folder_name'
    REQUIRED_COLUMNS = [DRUID_COLUMN, FOLDER_NAME_COLUMN].freeze

    # @return [Array<String>] error messages
    attr_reader :errors

    # @param csv [String] the manifest (already run through CsvUpload::Normalizer)
    # @param mount_path [String, nil] the mount path that folders must be within; nil skips that check
    def initialize(csv:, mount_path:)
      @csv = CSV.parse(csv, headers: true)
      @mount_path = mount_path
      @errors = []
    end

    # Missing columns or rows are reported alone, since the row checks would just be noise.
    def valid?
      validate_columns
      validate_rows if errors.empty?
      return false if errors.any?

      validate_blank_cells
      validate_duplicate_druids
      validate_shared_folder_names
      validate_folder_names_within_mount_path if mount_path
      errors.empty?
    end

    private

    attr_reader :csv, :mount_path

    def validate_columns
      missing_columns = REQUIRED_COLUMNS - csv.headers
      errors << "Missing columns: #{missing_columns.join(', ')}." if missing_columns.any?
    end

    def validate_rows
      errors << 'No rows.' if csv.empty?
    end

    def validate_blank_cells
      REQUIRED_COLUMNS.each do |column|
        # Row numbers start at 2 since the header is row 1.
        row_numbers = csv.each.with_index(2).filter_map { |row, row_number| row_number if row[column].blank? }
        errors << "Blank #{column} in rows: #{row_numbers.join(', ')}." if row_numbers.any?
      end
    end

    def validate_duplicate_druids
      duplicate_druids = present_values(DRUID_COLUMN).tally.select { |_druid, count| count > 1 }.keys
      errors << "Duplicate druids: #{duplicate_druids.join(', ')}." if duplicate_druids.any?
    end

    def validate_shared_folder_names
      druids_by_folder_name = rows_with_druid_and_folder_name.group_by { |row| row[FOLDER_NAME_COLUMN] }
                                                             .transform_values { |rows| rows.pluck(DRUID_COLUMN).uniq }
      shared_folder_names = druids_by_folder_name.select { |_folder_name, druids| druids.size > 1 }.keys
      errors << "Folders used by more than one druid: #{shared_folder_names.join(', ')}." if shared_folder_names.any?
    end

    # Lexical, so that the folders need not exist yet.
    def validate_folder_names_within_mount_path
      root_path = Pathname.new(mount_path).cleanpath
      escaping_folder_names = present_values(FOLDER_NAME_COLUMN).uniq.reject do |folder_name|
        root_path.join(folder_name).cleanpath.ascend.drop(1).include?(root_path)
      end
      errors << "Folders outside the mount path: #{escaping_folder_names.join(', ')}." if escaping_folder_names.any?
    end

    def present_values(column)
      csv.filter_map { |row| row[column].presence }
    end

    def rows_with_druid_and_folder_name
      csv.select { |row| row[DRUID_COLUMN].present? && row[FOLDER_NAME_COLUMN].present? }
    end
  end
end
