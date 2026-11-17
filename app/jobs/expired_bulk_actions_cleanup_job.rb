# frozen_string_literal: true

# Job that destroys bulk actions (and their files) of the types that expire, once they have expired.
class ExpiredBulkActionsCleanupJob < ApplicationJob
  queue_as :cleanup

  def perform
    BulkActions.all.select(&:expires_after).each do |bulk_action_config|
      BulkAction.where(action_type: bulk_action_config.action_type,
                       created_at: ...bulk_action_config.expires_after.ago)
                .where.not(status: %w[queued started cancelling])
                .find_each(&:destroy!)
    end
  end
end
