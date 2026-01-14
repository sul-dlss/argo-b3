# frozen_string_literal: true

module BulkActions
  # Job to close objects
  class CloseVersionJob < DruidsJob
    # Close version for a single object
    class JobItem < BaseJobItem
      def perform
        return unless check_update_ability?

        close_version_if_needed!(force: true)
        success!(message: 'Object successfully closed')
      end
    end
  end
end
