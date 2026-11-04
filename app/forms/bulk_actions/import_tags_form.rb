# frozen_string_literal: true

module BulkActions
  # Form object for import tags bulk action.
  # The CSV has no header row: each row is a druid followed by the tags for that object.
  class ImportTagsForm < BasicCsvForm
    def normalized_csv_file
      @normalized_csv_file ||= rows.map(&:to_csv).join
    end

    private

    # @return [Array<Array<String>>] the rows as uploaded (without blank cells), for reporting invalid druids
    def uploaded_rows
      @uploaded_rows ||= CSV.parse(CsvUpload::Normalizer.read(csv_file.path, headers: false))
    end

    # @return [Array<Array<String>>] the rows, with a prefixed druid
    def rows
      @rows ||= uploaded_rows.map { |uploaded_row| prefixed_row(uploaded_row) }
    end

    def prefixed_row(uploaded_row)
      druid, *tags = uploaded_row
      [DruidSupport.prefixed_druid_from(druid.sub(/\Adruid:/i, 'druid:')), *tags]
    end

    def validate_normalized_csv
      return errors.add(:csv_file, :invalid, message: 'has no rows') if rows.empty?

      uploaded_rows.each.with_index(1) do |uploaded_row, line_number|
        row_errors(uploaded_row).each do |message|
          errors.add(:csv_file, :invalid, message: "row #{line_number}: #{message}")
        end
      end

      duplicate_druids.each do |druid|
        errors.add(:csv_file, :invalid, message: "#{druid} is in more than one row")
      end
    end

    def duplicate_druids
      rows.map(&:first).tally.select { |_druid, count| count > 1 }.keys
    end

    # @param uploaded_row [Array<String>] the row as uploaded, so that an invalid druid is reported as entered
    def row_errors(uploaded_row)
      druid, *tags = prefixed_row(uploaded_row)
      invalid_tags = tags.grep_v(OtherTagForm::VALID_TAG_PATTERN)
      [].tap do |messages|
        messages << "invalid druid: #{uploaded_row.first}" unless DruidValidator::PATTERN.match?(druid)
        messages << "invalid tags: #{invalid_tags.join(', ')}" if invalid_tags.any?
      end
    end
  end
end
