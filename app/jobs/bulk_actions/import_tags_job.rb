# frozen_string_literal: true

module BulkActions
  # Job to replace administrative tags from a CSV file.
  # Unlike most CSV jobs, the CSV has no header row: each row is a druid followed by the tags for that object.
  # A row with only a druid removes all of the object's tags.
  class ImportTagsJob < BaseCsvJob
    def csv
      @csv ||= CSV.parse(@csv_file)
    end

    private

    # Import tags CSVs have no header row, so the first row is a data row.
    def first_row_number
      1
    end

    # The druid is always the first column.
    def druid_for(row)
      row.first
    end

    # There is no druid column, since there is no header row.
    def check_druid_column?
      true
    end

    # Replace the tags for a single object from a CSV row
    class JobItem < BaseCsvJobItem
      def perform
        return unless check_update_ability?

        Sdr::AdministrativeTags.replace(druid:, tags:)
        success!(message: tags.empty? ? 'Removed all tags' : "Replaced tags (#{tags.join(', ')})")
      end

      private

      def tags
        row.drop(1)
      end
    end
  end
end
