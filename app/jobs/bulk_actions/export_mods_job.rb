# frozen_string_literal: true

require 'zip'

module BulkActions
  # Export MODS XML for one or more objects as a zip file.
  class ExportModsJob < DruidsJob
    def perform_bulk_action
      Zip::File.open(bulk_action.export_filepath(:mods), create: true) do |export_zip|
        super(export_zip:)
      end
    end

    # Export MODS XML for a single object
    class JobItem < BaseJobItem
      def initialize(export_zip:, **)
        @export_zip = export_zip
        super(**)
      end

      def perform
        return unless check_read_ability?

        mods_xml = PurlFetcher::Client::Mods.create(cocina: cocina_object)
        export_zip.get_output_stream("#{DruidSupport.bare_druid_from(druid)}.xml") { |stream| stream.puts(mods_xml) }
        success!(message: 'Exported MODS XML')

        # Commit every 250 items to limit memory usage.
        export_zip.commit if (index % 250).zero?
      end

      private

      attr_reader :export_zip
    end
  end
end
