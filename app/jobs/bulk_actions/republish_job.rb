# frozen_string_literal: true

module BulkActions
  # Job to republish objects
  class RepublishJob < DruidsJob
    # Republish a single object
    class JobItem < BaseJobItem
      def perform
        return unless check_update_ability?
        return failure!(message: 'Not an item or collection') if not_publishable?
        return failure!(message: 'Never previously published') unless Sdr::WorkflowService.published?(druid:)

        Sdr::Repository.publish(druid:, lane_id: 'low')
        success!(message: 'Successfully republished')
      end

      def not_publishable?
        cocina_object.admin_policy? || CocinaSupport.agreement?(cocina_object)
      end
    end
  end
end
