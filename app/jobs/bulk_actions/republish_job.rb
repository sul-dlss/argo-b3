# frozen_string_literal: true

module BulkActions
  # Job to republish objects
  class RepublishJob < Job
    # Republish a single object
    class Item < JobItem
      def perform
        return failure!(message: 'Not an item or collection') if not_publishable?
        return failure!(message: 'Never previously published') unless Sdr::WorkflowService.published?(druid:)

        Dor::Services::Client.object(druid).publish(lane_id: 'low')
        success!(message: 'Successfully republished')
      end

      def not_publishable?
        cocina_object.admin_policy? || cocina_object.type == Cocina::Models::ObjectType.agreement
      end
    end
  end
end
