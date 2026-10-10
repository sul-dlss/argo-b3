# frozen_string_literal: true

# Model for the structure (content) of an object
#
# Note that when a Content is marked as immutable, it means that the content
# reflects the actual content for the specific version of the cocina object identified by the lock.
# Lock is an attribute of this model and records the lock (ETAG) of the cocina object.
# When Content is marked as not immutable, it means that the content is being
# updated, e.g., as part of managing files, and may have deviated from the actual content.
class Content < ApplicationRecord
  has_many :content_file_sets, -> { order(:position) }, inverse_of: :content, dependent: :destroy
  has_many :content_files, through: :content_file_sets
  has_many :content_file_binaries, inverse_of: :content, dependent: :destroy

  scope :with_structural_associations, -> { includes(content_file_sets: { content_files: :content_file_binary }) }

  # Staging changes the lock and immutability of the Content being staged, so this is not scoped by either.
  # @param druid [String] the druid of the object
  # @return [Content, nil] the most recently updated Content for the druid that is staging or failed staging
  def self.latest_staging_activity(druid:)
    where(druid:).with_staging_states(:staging, :staging_failed).order(updated_at: :desc).first
  end

  # Staging is retried by starting staging again from staging_failed.
  state_machine :staging_state, initial: :staging_not_in_progress do
    event :staging_started do
      transition %i[staging_not_in_progress staging_failed] => :staging
    end

    event :staging_completed do
      transition staging: :staging_not_in_progress
    end

    event :staging_errored do
      transition staging: :staging_failed
    end

    event :staging_failure_cleared do
      transition staging_failed: :staging_not_in_progress
    end
  end

  state_machine :mount_state, initial: :discovery_not_in_progress do
    event :discovery_started do
      transition discovery_not_in_progress: :discovering
    end

    event :discovery_completed do
      transition discovering: :discovery_not_in_progress
    end
  end
end
