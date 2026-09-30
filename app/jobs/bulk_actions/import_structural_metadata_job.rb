# frozen_string_literal: true

module BulkActions
  # Job to import structural metadata from a CSV file.
  # Unlike most CSV jobs, an object may have multiple rows (one per file), so rows are grouped by druid.
  class ImportStructuralMetadataJob < ClosingCsvJob
    def perform_bulk_action
      return unless check_druid_column?

      fail_blank_druid_rows

      rows_by_druid.each do |druid, druid_rows|
        # The index is the line number of the first row for the druid.
        index = druid_rows.first.fetch(:index)
        perform_item_class.new(druid:, index:, job: self, rows: druid_rows.pluck(:row),
                               line_numbers: druid_rows.pluck(:index)).perform
      rescue Sdr::Repository::NotFoundResponse
        failure!(druid:, message: 'Error: Object not found', index:)
      rescue StandardError => e
        failure!(druid:, message: "Error: #{e.class} #{e.message}", index:)
      end
    end

    # Each row without a druid is counted (as a failure) separately.
    def druid_count
      rows_by_druid.size + blank_druid_line_numbers.size
    end

    # Imports structural metadata for a single object from its CSV rows
    class JobItem < BaseJobItem
      # @param rows [Array<CSV::Row>] the CSV rows for the druid
      # @param line_numbers [Array<Integer>] the spreadsheet line number of each row
      def initialize(rows:, line_numbers:, **)
        @rows = rows
        @line_numbers = line_numbers
        super(**)
      end

      def perform # rubocop:disable Metrics/AbcSize
        return unless check_update_ability?
        return unless check_object_type?(allow_collection: false, allow_admin_policy: false)

        update_result = StructuralCsv::Import.call(cocina_object:, csv_rows: rows, line_numbers:)
        return failure!(message: update_result.failure.join('; ')) if update_result.failure?

        structural = update_result.value!
        return success!(message: 'Structural metadata unchanged') if cocina_object.structural == structural

        # Validates before opening a version so that invalid structural does not leave an open version.
        validate_result = CocinaSupport.validate(cocina_object, structural:)
        return failure!(message: "Validation failed (#{validate_result.failure})") if validate_result.failure?

        open_new_version_if_needed!(description: description_msg)

        @cocina_object = cocina_object.new(structural:)
        Sdr::Repository.update(cocina_object:, user_name: user_id, description: description_msg)

        close_version_if_needed!
        success!(message: 'Structural metadata updated')
      end

      def success!(message:)
        job.success!(druid:, message: "Success: #{message}", index:)
      end

      def failure!(message:)
        job.failure!(druid:, message: "Error: #{message}", index:)
      end

      private

      attr_reader :rows, :line_numbers

      def description_msg
        'Updated structural metadata'
      end
    end

    private

    def fail_blank_druid_rows
      blank_druid_line_numbers.each do |index|
        failure!(druid: nil, message: 'Error: Missing druid', index:)
      end
    end

    # @return [Array<Hash>] each row with its spreadsheet line number
    def indexed_rows
      @indexed_rows ||= csv.each.with_index(2).map { |row, index| { row:, index: } }
    end

    # @return [Hash<String, Array<Hash>>] map of druid to the rows (and their line numbers) for that druid
    def rows_by_druid
      @rows_by_druid ||= indexed_rows.reject { |indexed_row| blank_druid?(indexed_row) }
                                     .group_by { |indexed_row| indexed_row[:row][DRUID_COLUMN] }
    end

    # @return [Array<Integer>] line numbers of rows without a druid
    def blank_druid_line_numbers
      @blank_druid_line_numbers ||= indexed_rows.select { |indexed_row| blank_druid?(indexed_row) }.pluck(:index)
    end

    def blank_druid?(indexed_row)
      indexed_row[:row][DRUID_COLUMN].blank?
    end
  end
end
