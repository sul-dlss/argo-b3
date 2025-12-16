# frozen_string_literal: true

module BulkActions
  # Bulk action job to reindex objects in Solr
  class ReindexJob < ApplicationJob
    def perform(bulk_action:, druids:)
      # Not implemented yet
    end
  end
end
