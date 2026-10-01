# frozen_string_literal: true

module BulkActions
  # A job that exports structural metadata to CSV for one or more objects
  class ExportStructuralMetadataJob < DruidsJob
    def perform_bulk_action
      export_filepath = bulk_action.export_filepath(:structural_metadata)
      CSV.open(export_filepath, 'w', write_headers: true, headers: StructuralCsv::Export::HEADERS) do |export_csv|
        super(export_csv:)
      end
    end

    def csv_download_path
      File.join(bulk_action.output_directory, Settings.export_structural_job.csv_filename)
    end

    # Exports structural metadata for a single object
    class JobItem < BaseJobItem
      def initialize(export_csv:, **)
        @export_csv = export_csv
        super(**)
      end

      def perform
        return failure!(message: 'No structural metadata to export') if no_structural?

        content = Contents::Builder.build(cocina_object:)
        StructuralCsv::Export.new(content:).rows do |row|
          export_csv << row
        end
        success!(message: 'Exported structural metadata')
      end

      def no_structural?
        !cocina_object.dro? || Array(cocina_object.structural&.contains).empty?
      end

      private

      attr_reader :export_csv
    end
  end
end
