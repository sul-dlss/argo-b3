# frozen_string_literal: true

# Model for tracking a bulk action.
class BulkAction < ApplicationRecord
  belongs_to :user

  enum :status, { created: 'created', queued: 'queued', started: 'started', completed: 'completed' }, validate: true

  def bulk_action_config
    BulkActions.find_config(action_type)
  end

  def enqueue_job(**params)
    bulk_action_config.job.perform_later(bulk_action: self, **params)
    queued!
  end
end
