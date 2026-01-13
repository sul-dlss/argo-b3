# frozen_string_literal: true

module BulkActions
  # Job to export Cocina JSON
  class ExportCocinaJsonJob < Job
    def perform_bulk_action
      super

      gzip_file
    end

    def export_file
      @export_file ||= File.open(export_filepath, 'w')
    end

    # Export a single object
    class Item < JobItem
      def perform
        export_file << "#{cocina_object.to_json}\n"
        success!(message: 'Exported full Cocina JSON')
      end
    end

    private

    def export_filepath
      gzip_export_filepath.delete_suffix('.gz')
    end

    def gzip_export_filepath
      bulk_action.export_filepath
    end

    def gzip_file
      export_file.close
      gzip = ActiveSupport::Gzip.compress(File.read(export_filepath))
      File.write(gzip_export_filepath, gzip, mode: 'wb')
      FileUtils.rm_f(export_filepath)
    end
  end
end
