# frozen_string_literal: true

module BulkActions
  # Bulk action job to reindex objects in Solr
  class ReindexJob < Job
    # Reindex a single object
    class Item < JobItem
      def perform
        Dor::Services::Client.object(druid).reindex
        success!(message: 'Reindex successful')
      end
    end
  end
end
