# frozen_string_literal: true

module BulkActions
  # Form object for create virtual object bulk action.
  # The CSV has no header row: each row is a virtual object druid followed by its constituent druids.
  # Only the druids are validated here; the objects are validated per virtual object by the job (and DSA).
  class CreateVirtualObjectForm < BasicCsvForm
    def normalized_csv_file
      @normalized_csv_file ||= rows.map(&:to_csv).join
    end

    private

    # @return [Array<Array<String>>] the rows as uploaded (without blank cells), for reporting invalid druids
    def uploaded_rows
      @uploaded_rows ||= CSV.parse(CsvUpload::Normalizer.read(csv_file.path, headers: false))
    end

    # @return [Array<Array<String>>] the rows, with prefixed druids
    def rows
      @rows ||= uploaded_rows.map { |uploaded_row| prefixed_druids(uploaded_row) }
    end

    def prefixed_druids(uploaded_row)
      uploaded_row.map { |druid| DruidSupport.prefixed_druid_from(druid.sub(/\Adruid:/i, 'druid:')) }
    end

    def validate_normalized_csv
      return errors.add(:csv_file, :invalid, message: 'has no rows') if rows.empty?

      uploaded_rows.each.with_index(1) do |uploaded_row, line_number|
        row_errors(uploaded_row).each do |message|
          errors.add(:csv_file, :invalid, message: "row #{line_number}: #{message}")
        end
      end

      duplicate_virtual_object_druids.each do |druid|
        errors.add(:csv_file, :invalid, message: "#{druid} is the virtual object in more than one row")
      end
    end

    def duplicate_virtual_object_druids
      rows.map(&:first).tally.select { |_druid, count| count > 1 }.keys
    end

    # @param uploaded_row [Array<String>] the row as uploaded, so that invalid druids are reported as entered
    def row_errors(uploaded_row)
      prefixed_row = prefixed_druids(uploaded_row)
      virtual_object_druid, *constituent_druids = prefixed_row
      invalid_druids = uploaded_row.reject.with_index do |_druid, index|
        DruidValidator::PATTERN.match?(prefixed_row[index])
      end
      [].tap do |messages|
        messages << "invalid druids: #{invalid_druids.join(', ')}" if invalid_druids.any?
        messages << 'no constituent druids' if constituent_druids.empty?
        if constituent_druids.include?(virtual_object_druid)
          messages << "#{virtual_object_druid} cannot be a constituent of itself"
        end
      end
    end
  end
end
