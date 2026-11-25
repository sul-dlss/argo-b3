# frozen_string_literal: true

# A Deposit started in Argo-B3, remembered from when it starts until it is Complete, so that its outcome can be
# reported to the depositing user (see PollTrackedDepositsJob). Tracking ends by destroying the record.
#
# A Tracked Deposit is In Error while its staging has failed (staging_failed_at) or a Process is in error
# (process_errored_at). Each time it goes In Error for either cause, the depositing user is notified
# (DepositFailedNotifier); the times let the Notification's delayed email tell whether it has left In Error since.
class TrackedDeposit < ApplicationRecord
  CAUSES = %w[staging process].freeze

  belongs_to :user

  # Starts tracking the Deposit of a version. Depositing the same version again (e.g., after staging failed) tracks
  # it for the user who deposited it last.
  # @param druid [String]
  # @param version [Integer] the version being deposited
  # @param user [User] the depositing user
  def self.track!(druid:, version:, user:)
    # An upsert, so that concurrent deposits of the same version (e.g., a double submit) can't violate the unique index.
    upsert({ druid:, version:, user_id: user.id }, unique_by: %i[druid version]) # rubocop:disable Rails/SkipsModelValidations
  end

  # @param druid [String]
  # @return [TrackedDeposit, nil] the Tracked Deposit of the object's latest tracked version
  def self.latest_for(druid:)
    where(druid:).order(:version).last
  end

  # Staging is retried (by saving or depositing from manage files), so no Deposit of the object is In Error from
  # staging any longer.
  # @param druid [String]
  def self.staging_retried!(druid:)
    where(druid:).where.not(staging_failed_at: nil).update_all(staging_failed_at: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  # @param status [Dor::Services::Client::ObjectVersion::VersionStatus, nil] the object's version status; nil if the
  #   object was not found
  # @return [Boolean] true if the tracked version has finished accessioning
  def complete?(status)
    return false unless status

    # A later version can be opened only once the tracked version has finished accessioning.
    status.version > version || (status.version == version && status.closed? && !status.accessioning?)
  end

  # @param status [Dor::Services::Client::ObjectVersion::VersionStatus, nil] the object's version status; nil if the
  #   object was not found
  # @return [Boolean] true if the tracked version is no longer in flight, e.g., the object was purged or the draft
  #   discarded
  def abandoned?(status)
    status.nil? || status.version < version
  end

  # Records that staging failed during the Deposit, and notifies the depositing user.
  # @param title [String] the object's title
  # @param error_summary [String] what went wrong and what to do about it
  def staging_failed!(title:, error_summary:)
    went_in_error!(cause: 'staging', title:, error_summary:)
  end

  # Records the Processes in error found while polling. Notifies the depositing user when the Deposit goes from no
  # Process in error to some, including after a failed retry; does nothing while the errors persist.
  # @param workflow_errors [Array<String>] the Processes in error, as workflow:process:message; empty if none
  # @param title [String] the object's title
  def process_errors_found!(workflow_errors:, title:)
    if workflow_errors.empty?
      update!(process_errored_at: nil) if process_errored_at
    elsif process_errored_at.nil?
      went_in_error!(cause: 'process', title:, error_summary: workflow_errors.join('; '))
    end
  end

  # @param cause [String] one of CAUSES
  # @param time [Time]
  # @return [Boolean] true if the Deposit has been In Error for the cause since (at or before) the time, i.e., it has
  #   not left In Error for that cause since
  def in_error_since?(cause:, time:)
    errored_at = cause == 'staging' ? staging_failed_at : process_errored_at
    errored_at.present? && !errored_at.after?(time)
  end

  private

  # The time is recorded before notifying, so that it precedes the Notification; if notifying fails, it is cleared,
  # so that the next error (or, for Processes, the next poll) notifies.
  def went_in_error!(cause:, title:, error_summary:)
    attribute = cause == 'staging' ? :staging_failed_at : :process_errored_at
    update!(attribute => Time.current)
    DepositFailedNotifier.with(druid:, version:, title:, cause:, error_summary:).deliver(user, queue: :real_time)
  rescue StandardError
    update!(attribute => nil)
    raise
  end
end
