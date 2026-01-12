# frozen_string_literal: true

module BulkActions
  # Bulk action to purge unpublished objects
  class PurgeJob < BulkActions::BulkActionJob
    # Purge a single object
    class PurgeJobItem < BulkActions::BulkActionJobItem
      def perform
        return unless check_update_ability?

        unless purge_service.can_purge?
          return failure!(message: 'Cannot purge item because it has already been submitted')
        end

        purge_service.purge(user_name: user)

        success!(message: 'Purge successful')
      end

      def purge_service
        @purge_service ||= Sdr::PurgeService.new(druid:)
      end
    end
  end
end
