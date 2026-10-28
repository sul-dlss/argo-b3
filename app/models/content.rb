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

  # @param cocina_object [Cocina::Models::DROWithMetadata] the Cocina object
  # @return [Content, nil] the mutable Content for the object's current lock
  def self.mutable_for(cocina_object)
    find_by(druid: cocina_object.externalIdentifier, lock: cocina_object.lock, immutable: false)
  end

  # Staging changes the lock and immutability of the Content being staged, so this is not scoped by either.
  # @param druid [String] the druid of the object
  # @return [Content, nil] the most recently updated Content for the druid that is staging or failed staging
  def self.latest_staging_activity(druid:)
    where(druid:).with_staging_states(:staging, :staging_failed).order(updated_at: :desc).first
  end

  # Called once the object or its draft is gone from SDR, so a failure is reported rather than raised.
  # @param druid [String] the druid of the object
  def self.delete_mutable_and_staged_files(druid:)
    where(druid:, immutable: false).destroy_all
    StagingSupport.delete_staged_files(druid:)
  rescue StandardError => e
    Rails.logger.error(e.full_message)
    Honeybadger.notify(e, context: { druid: })
  end

  # Staging supersedes staging failures for other Contents for the druid (e.g., one for an earlier lock).
  # @param stage_files_options [Hash] additional keyword arguments for StageFilesJob#perform
  def start_staging!(user:, **stage_files_options)
    clear_other_staging_failures!
    staging_started!
    StageFilesJob.perform_later(content: self, user:, **stage_files_options)
  end

  # The assembly workflow reads these from its context to decide whether to run OCR.
  # @return [Hash] the workflow context to start accessioning with
  def workflow_context
    return {} unless perform_ocr

    { runOCR: true, ocrLanguages: ocr_languages }
  end

  # Memoized, since several populators and views may ask for the same Content.
  # @return [Boolean] true if any of the binaries have hierarchical filepaths (e.g., folder1/image1.tif)
  def hierarchical_filepaths?
    return @hierarchical_filepaths if defined?(@hierarchical_filepaths)

    @hierarchical_filepaths = content_file_binaries.where('cardinality(path_parts) > 0').exists?
  end

  # A background job may change the lock of a Content that is staging or discovering.
  def staging_or_discovering?
    staging? || discovering?
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

  private

  def clear_other_staging_failures!
    Content.where(druid:).where.not(id:).with_staging_state(:staging_failed).find_each(&:staging_failure_cleared!)
  end
end
