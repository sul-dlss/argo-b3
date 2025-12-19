# frozen_string_literal: true

module BulkActions
  # A job that exports tags to CSV for one or more objects
  class ExportTagsJob < BulkActionJob
    def export_file
      @export_file ||= CSV.open(bulk_action.export_filepath, 'w')
    end

    # Export tags for single object
    class ExportTagsJobItem < BulkActionJobItem
      def perform
        export_file << [druid, *export_tags]
        success!(message: 'Exported tags')
      end

      private

      def export_tags
        Dor::Services::Client.object(druid).administrative_tags.list
      end
    end
  end
end
