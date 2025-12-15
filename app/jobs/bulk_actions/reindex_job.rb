# frozen_string_literal: true

module BulkActions
  # Bulk action job to reindex objects in Solr
  class ReindexJob < BulkActionJob
    # Reindex a single object
    class ReindexJobItem < BulkActionJobItem
      def perform
        Dor::Services::Client.object(druid).reindex
        success!(message: 'Reindex successful')
      end
    end
  end
end
