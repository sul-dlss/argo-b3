# frozen_string_literal: true

module BulkActions
  # Job to import structural metadata from a CSV file (roughly equivalent to Argo's ImportStructuralJob).
  # Unlike other CSV jobs, an object may have multiple rows, so the job is performed per druid rather than per row.
  class ImportStructuralMetadataJob < ClosingCsvJob
    def perform_bulk_action
      return unless check_druid_column? && check_required_columns?

      blank_druid_rows.map(&:first).each do |row_number|
        failure!(druid: nil, message: 'Error: Missing druid', index: row_number)
      end

      rows_by_druid.each do |druid, rows|
        perform_druid(druid:, rows:)
      end
    end

    # Each druid is counted once, regardless of how many rows it has. Rows with a blank druid are each counted
    # (as failures).
    def druid_count
      rows_by_druid.size + blank_druid_rows.size
    end

    private

    # Each row paired with its spreadsheet row number.
    # @return [Array<Array(Integer, CSV::Row)>]
    def numbered_rows
      @numbered_rows ||= csv.each.with_index(2).map { |row, row_number| [row_number, row] }
    end

    def blank_druid_rows
      @blank_druid_rows ||= numbered_rows.select { |_row_number, row| row[DRUID_COLUMN].blank? }
    end

    # Druids are normalized (e.g., the structural metadata export uses bare druids), so that rows with bare and
    # prefixed druids for the same object are grouped together.
    # @return [Hash<String, Array<Array(Integer, CSV::Row)>>] the rows for each druid, in the order in which each
    #   druid first appears
    def rows_by_druid
      @rows_by_druid ||= (numbered_rows - blank_druid_rows).group_by do |_row_number, row|
        DruidSupport.prefixed_druid_from(row[DRUID_COLUMN].strip)
      end
    end

    # The druid's first row number is used as the index for logging.
    def perform_druid(druid:, rows:)
      index = rows.first.first
      perform_item_class.new(druid:, index:, job: self, rows:).perform
    rescue Sdr::Repository::NotFoundResponse
      failure!(druid:, message: 'Error: Object not found', index:)
    rescue StandardError => e
      failure!(druid:, message: "Error: #{e.class} #{e.message}", index:)
    end

    def check_required_columns?
      missing_columns = StructuralCsv::Validator::REQUIRED_COLUMNS - csv.headers
      return true if missing_columns.empty?

      missing_columns.each { |column| log("Missing required column \"#{column}\"") }
      bulk_action.update(druid_count_fail: druid_count)
      false
    end

    # Import structural metadata from the rows for a single object
    class JobItem < BaseJobItem
      DESCRIPTION = 'Updated structural metadata'

      # @param rows [Array<Array(Integer, CSV::Row)>] the rows for the object, each paired with its spreadsheet
      #   row number
      def initialize(rows:, **)
        @rows = rows
        super(**)
      end

      def perform # rubocop:disable Metrics/AbcSize
        return unless check_update_ability? && check_object_type?(allow_collection: false, allow_admin_policy: false)
        return unless check_existing_content?

        @content = Contents::Builder.call(cocina_object:, immutable: false)
        import_result = StructuralCsv::Import.call(rows:, content:)
        return failure!(message: error_message(import_result.failure)) if import_result.failure?

        Contents::ExternalIdentifierMinter.call(content:)
        return success!(message: 'Structure unchanged') if structural_unchanged?

        open_new_version_if_needed!(description: DESCRIPTION)
        # Rebuilt from the cocina object for the opened version.
        Sdr::Repository.update(cocina_object: updated_cocina_object, user_name: user_id, description: DESCRIPTION)
        close_version_if_needed!
        success!(message: DESCRIPTION)
      ensure
        content&.destroy!
      end

      def success!(message:)
        job.success!(druid:, message: "Success: #{message}", index:)
      end

      def failure!(message:)
        job.failure!(druid:, message: "Error: #{message}", index:)
      end

      private

      attr_reader :rows, :content

      # A mutable Content for the object (e.g., left by the Contents edit page) would conflict with the Content built
      # by this job (since there is a unique index on druid, lock, and immutable). It is destroyed, since the import
      # will make it stale anyway, unless files are being staged or discovered.
      def check_existing_content?
        existing_content = Content.find_by(druid:, lock: cocina_object.lock, immutable: false)
        return true if existing_content.nil?

        if existing_content.staging? || existing_content.discovering?
          failure!(message: 'Files are being staged or discovered for this object')
          return false
        end

        existing_content.destroy!
        true
      end

      def updated_cocina_object
        CocinaObjectMutators::StructuralMutator.call(cocina_object:, content:)
      end

      # File set and file versions are ignored, since StructuralMutator sets them to the object's version.
      # Nil values are ignored, since an attribute may be either nil or omitted depending on how the object was
      # last updated (e.g., an explicit location: nil persists in SDR, while StructuralMutator omits it).
      def structural_unchanged?
        normalized_structural(updated_cocina_object) == normalized_structural(cocina_object)
      end

      def normalized_structural(cocina_object)
        deep_compact(cocina_object.structural.to_h).tap do |structural|
          Array(structural[:contains]).each do |file_set|
            file_set.delete(:version)
            Array(file_set.dig(:structural, :contains)).each { |file| file.delete(:version) }
          end
        end
      end

      def deep_compact(value)
        case value
        when Hash
          value.compact.transform_values { |nested_value| deep_compact(nested_value) }
        when Array
          value.map { |nested_value| deep_compact(nested_value) }
        else
          value
        end
      end

      # @param errors [Array<StructuralCsv::ValidationError>]
      def error_message(errors)
        errors.map { |error| "Row #{error.line_number}: #{error.reason}" }.join('; ')
      end
    end
  end
end
