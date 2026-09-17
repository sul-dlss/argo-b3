# frozen_string_literal: true

module BulkActions
  # Job to redeposit objects.
  class RedepositJob < DruidsJob
    # Redeposit a single object.
    class JobItem < BaseJobItem
      def perform
        return unless check_update_ability?

        close_version_if_needed!(force: true)
        success!(message: 'Object successfully redeposited')
      end
    end
  end
end
