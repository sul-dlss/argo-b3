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
  # The query for not busy?
  scope :not_busy, lambda {
    where.not(staging_state: 'staging').where.not(mount_state: 'discovering')
         .where.not(structuring_state: 'structuring')
  }

  # The steps of managing files, in order. Agreements have no item details step.
  enum :step, { details: 'details', files: 'files', structure: 'structure', deposit: 'deposit' }, suffix: true,
                                                                                                  validate: true

  # The message of errors refusing a change while busy?
  BUSY_MESSAGE = 'Files are being staged, discovered, or structured'

  # The item details chosen while managing files, which are saved to the object by saving or depositing.
  ITEM_DETAILS_ATTRIBUTES = %w[content_type viewing_direction with_embargo embargo_release_date access_view
                               access_download access_location embargo_view embargo_download embargo_location
                               overwrite_file_access version_description].freeze

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

  # @param druids [Array<String>]
  # @return [Hash<String, Content>] the latest_staging_activity for each druid that has one, keyed by druid
  def self.latest_staging_activities(druids:)
    where(druid: druids).with_staging_states(:staging, :staging_failed).order(:updated_at).index_by(&:druid)
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

  # Accessioning reads these from its context to decide whether to start OCR or speech to text.
  # Only the text extraction for the content type is requested, since the content type may have changed since
  # the settings were saved.
  # @param content_type [String] the cocina type URI of the object being accessioned
  # @return [Hash] the workflow context to start accessioning with
  def workflow_context(content_type:)
    if perform_ocr && Sdr::TextExtraction.ocr_type?(content_type)
      { runOCR: true, ocrLanguages: ocr_languages }
    elsif perform_speech_to_text && Sdr::TextExtraction.speech_to_text_type?(content_type)
      { runSpeechToText: true }
    else
      {}
    end
  end

  # Memoized, since several populators and views may ask for the same Content.
  # @return [Boolean] true if any of the binaries have hierarchical filepaths (e.g., folder1/image1.tif)
  def hierarchical_filepaths?
    return @hierarchical_filepaths if defined?(@hierarchical_filepaths)

    @hierarchical_filepaths = content_file_binaries.where('cardinality(path_parts) > 0').exists?
  end

  # A background job may change the lock or the structure of a Content that is busy, so changes are refused.
  def busy?
    staging? || discovering? || structuring?
  end

  # @param append [Boolean] whether to add the unassociated files to the existing resources rather than replacing them
  def start_structuring!(append:)
    structuring_started!
    StructureFilesJob.perform_later(content: self, append:)
  end

  # @return [String, nil] 'structured' or 'structuring_failed' until the result is taken, otherwise nil
  def structuring_result
    structuring_state if structured? || structuring_failed?
  end

  # The result is shown once, so taking it clears it.
  # @return [String, nil] the structuring_result
  def take_structuring_result!
    structuring_result.tap { |result| structuring_result_shown! if result }
  end

  # Item details are saved once a step is left, so none are saved before then.
  # @return [Hash] the saved item details as ContentsItemForm params, or empty if none are saved
  def item_details_params
    return {} if content_type.nil?

    attributes.slice(*ITEM_DETAILS_ATTRIBUTES).symbolize_keys
  end

  # Returns to the first step and clears the item details, e.g., once they are saved to the object.
  def reset_manage_files_flow!
    update!(step: :details, **clear_item_details_attributes)
  end

  # Clears the item details, e.g., when the object was edited elsewhere so that they would overwrite the edit.
  def clear_item_details!
    update!(clear_item_details_attributes)
  end

  # Structuring and validating the structure use the selected access, which may not have been saved yet.
  # @param cocina_object [Cocina::Models::DROWithMetadata] the saved object
  # @return [Cocina::Models::DROWithMetadata] the object with the selected access, if any
  def with_selected_access(cocina_object)
    Contents::ApplySelectedAccess.call(cocina_object:, params: item_details_params)
  end

  # @param cocina_object [Cocina::Models::DROWithMetadata] the saved object
  # @return [String] the selected content type, which may not have been saved yet
  def selected_content_type(cocina_object)
    content_type || cocina_object.type
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

  # Structured and structuring_failed are kept until the result has been shown (see structuring_result_shown).
  state_machine :structuring_state, initial: :structuring_not_in_progress do
    event :structuring_started do
      transition %i[structuring_not_in_progress structured structuring_failed] => :structuring
    end

    event :structuring_completed do
      transition structuring: :structured
    end

    event :structuring_errored do
      transition structuring: :structuring_failed
    end

    event :structuring_result_shown do
      transition %i[structured structuring_failed] => :structuring_not_in_progress
    end
  end

  private

  def clear_item_details_attributes
    ITEM_DETAILS_ATTRIBUTES.index_with(nil)
  end

  def clear_other_staging_failures!
    Content.where(druid:).where.not(id:).with_staging_state(:staging_failed).find_each(&:staging_failure_cleared!)
  end
end
