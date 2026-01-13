# frozen_string_literal: true

module BulkActions
  # A job that exports structural metadata to CSV for one or more objects
  class ExportStructuralMetadataJob < Job
    def export_file
      @export_file ||= CSV.open(bulk_action.export_filepath, 'w', write_headers: true, headers: StructureSerializer::HEADERS)
    end

    def csv_download_path
      File.join(bulk_action.output_directory, Settings.export_structural_job.csv_filename)
    end

    # Exports structural metadata for a single object
    class Item < JobItem
      def perform
        return failure!(message: 'No structural metadata to export') if no_structural?

        StructureSerializer.new(druid, cocina_object.structural).rows do |row|
          export_file << row
        end
        success!(message: 'Exported structural metadata')
      end

      def no_structural?
        !cocina_object.dro? || Array(cocina_object.structural&.contains).empty?
      end
    end
  end
end
