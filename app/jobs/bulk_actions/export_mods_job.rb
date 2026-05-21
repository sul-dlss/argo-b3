# frozen_string_literal: true

require 'zip'

module BulkActions
  # Export MODS XML for one or more objects as a zip file.
  class ExportModsJob < DruidsJob
    def export_file
      @export_file ||= Zip::File.open(bulk_action.export_filepath, create: true)
    end

    # Export MODS XML for a single object
    class JobItem < BaseJobItem
      def perform
        return unless check_read_ability?

        mods_xml = PurlFetcher::Client::Mods.create(cocina: cocina_object)
        export_file.get_output_stream("#{DruidSupport.bare_druid_from(druid)}.xml") { |stream| stream.puts(mods_xml) }
        success!(message: 'Exported MODS XML')

        # Commit every 250 items to limit memory usage.
        export_file.commit if (index % 250).zero?
      end
    end
  end
end
