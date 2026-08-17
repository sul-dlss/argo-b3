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

  state_machine :staging_state, initial: :staging_not_in_progress do
    event :staging_started do
      transition staging_not_in_progress: :staging
    end

    event :staging_completed do
      transition staging: :staging_not_in_progress
    end
  end
end
