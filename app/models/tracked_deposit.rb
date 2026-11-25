# frozen_string_literal: true

# A Deposit started in Argo-B3, remembered from when it starts until it is Complete, so that its outcome can be
# reported to the depositing user (see PollTrackedDepositsJob). Tracking ends by destroying the record.
#
# A Tracked Deposit is In Error while its staging has failed (staging_failed_at) or a Process is in error
# (process_errored_at). Each time it goes In Error for either cause, the depositing user is notified
# (DepositFailedNotifier); the times let the Notification's delayed email tell whether it has left In Error since.
#
# A MID Item Deposit's Tracked Deposit belongs to its ItemDepositAction and never notifies on its own: its errors are
# recorded the same way, and it counts toward its Multi-Item Deposit's settling (see Settleable).
class TrackedDeposit < ApplicationRecord
  CAUSES = %w[staging process].freeze

  belongs_to :user
  belongs_to :item_deposit_action, optional: true

  scope :in_error, -> { where.not(staging_failed_at: nil).or(where.not(process_errored_at: nil)) }
  scope :not_in_error, -> { where(staging_failed_at: nil, process_errored_at: nil) }

  # Starts tracking the Deposit of a version. Depositing the same version again (e.g., after staging failed) tracks
  # it for the user who deposited it last. Depositing a MID Item Deposit's version again from manage files keeps
  # it part of its Multi-Item Deposit, so that the retry counts toward the Multi-Item Deposit's settling.
  # @param druid [String]
  # @param version [Integer] the version being deposited
  # @param user [User] the depositing user
  # @param item_deposit_action [ItemDepositAction, nil] the MID Item Deposit, if the Deposit is one
  def self.track!(druid:, version:, user:, item_deposit_action: nil)
    attributes = { druid:, version:, user_id: user.id }
    attributes[:item_deposit_action_id] = item_deposit_action.id if item_deposit_action
    # An upsert, so that concurrent deposits of the same version (e.g., a double submit) can't violate the unique index.
    upsert(attributes, unique_by: %i[druid version], update_only: attributes.keys - %i[druid version]) # rubocop:disable Rails/SkipsModelValidations
  end

  # A Process of the object in error is retried (or skipped or completed) in Argo-B3, so any Multi-Item Deposit the
  # object's Deposit belongs to has unsettled. The next poll finds whether a Process is still in error.
  # @param druid [String]
  def self.process_retried!(druid:)
    unsettle_multi_item_deposits!(where(druid:))
  end

  # @param tracked_deposits [ActiveRecord::Relation<TrackedDeposit>]
  def self.unsettle_multi_item_deposits!(tracked_deposits)
    item_deposit_actions = ItemDepositAction.where(id: tracked_deposits.select(:item_deposit_action_id))
    MultiItemDepositAction.unsettle!(item_deposit_actions.select(:multi_item_deposit_action_id))
  end
  private_class_method :unsettle_multi_item_deposits!

  # @param druid [String]
  # @return [TrackedDeposit, nil] the Tracked Deposit of the object's latest tracked version
  def self.latest_for(druid:)
    where(druid:).order(:version).last
  end

  # Staging is retried (by saving or depositing from manage files), so no Deposit of the object is In Error from
  # staging any longer.
  # @param druid [String]
  def self.staging_retried!(druid:)
    staging_failed = where(druid:).where.not(staging_failed_at: nil)
    unsettle_multi_item_deposits!(staging_failed)
    staging_failed.update_all(staging_failed_at: nil) # rubocop:disable Rails/SkipsModelValidations
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

  # Records that staging failed during the Deposit, and notifies the depositing user (unless it is a MID Item
  # Deposit, which only records it).
  # @param title [String, nil] the object's title; nil only for a MID Item Deposit
  # @param error_summary [String, nil] what went wrong and what to do about it; nil only for a MID Item Deposit
  # @return [Boolean] true if the depositing user was notified
  def staging_failed!(title: nil, error_summary: nil)
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
  # so that the next error (or, for Processes, the next poll) notifies. A MID Item Deposit never notifies on its own.
  # @return [Boolean] true if the depositing user was notified
  def went_in_error!(cause:, title:, error_summary:)
    attribute = cause == 'staging' ? :staging_failed_at : :process_errored_at
    update!(attribute => Time.current)
    return false if item_deposit_action_id

    DepositFailedNotifier.with(druid:, version:, title:, cause:, error_summary:).deliver(user, queue: :real_time)
    true
  rescue StandardError
    update!(attribute => nil)
    raise
  end
end
