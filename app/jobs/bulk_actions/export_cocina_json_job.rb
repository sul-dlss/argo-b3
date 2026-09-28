# frozen_string_literal: true

require 'zlib'

module BulkActions
  # Job to export Cocina JSON
  class ExportCocinaJsonJob < DruidsJob
    def perform_bulk_action
      Zlib::GzipWriter.open(bulk_action.export_filepath(:cocina_json)) do |export_gzip|
        super(export_gzip:)
      end
    end

    # Export a single object
    class JobItem < BaseJobItem
      def initialize(export_gzip:, **)
        @export_gzip = export_gzip
        super(**)
      end

      def perform
        export_gzip << "#{cocina_object.to_json}\n"
        success!(message: 'Exported full Cocina JSON')
      end

      private

      attr_reader :export_gzip
    end
  end
end
