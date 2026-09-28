# frozen_string_literal: true

module BulkActions
  # A job that exports tags to CSV for one or more objects
  class ExportTagsJob < DruidsJob
    def perform_bulk_action
      CSV.open(bulk_action.export_filepath(:tags), 'w') do |export_csv|
        super(export_csv:)
      end
    end

    # Export tags for single object
    class JobItem < BaseJobItem
      def initialize(export_csv:, **)
        @export_csv = export_csv
        super(**)
      end

      def perform
        export_csv << [DruidSupport.bare_druid_from(druid), *export_tags]
        success!(message: 'Exported tags')
      end

      private

      attr_reader :export_csv

      def export_tags
        Dor::Services::Client.object(druid).administrative_tags.list
      end
    end
  end
end
