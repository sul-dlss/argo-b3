# frozen_string_literal: true

# A Deposit started in Argo-B3, remembered from when it starts until it is Complete, so that its outcome can be
# reported to the depositing user (see PollTrackedDepositsJob). Tracking ends by destroying the record.
# A MID Item Deposit's Tracked Deposit belongs to its ItemDepositAction and never notifies on its own; it counts
# toward its Multi-Item Deposit's settling (see Settleable).
class TrackedDeposit < ApplicationRecord
  belongs_to :user
  belongs_to :item_deposit_action, optional: true

  # How long after a retry Solr may still show the retried Process in error.
  RETRY_GRACE_PERIOD = 2.minutes

  scope :not_in_error, -> { where(in_error: false) }

  # Starts tracking the Deposit of a version. Depositing the same version again (e.g., after staging failed) tracks
  # it for the user who deposited it last. Depositing a MID Item Deposit's version again from manage files keeps
  # it part of its Multi-Item Deposit, so that the retry counts toward the Multi-Item Deposit's settling.
  # @param druid [String]
  # @param version [Integer] the version being deposited
  # @param user [User] the depositing user
  # @param item_deposit_action [ItemDepositAction, nil] the MID Item Deposit, if the Deposit is one
  def self.track!(druid:, version:, user:, item_deposit_action: nil)
    attributes = { druid:, version:, user_id: user.id, in_error: false }
    update_only = %i[user_id in_error]
    if item_deposit_action
      attributes[:item_deposit_action_id] = item_deposit_action.id
      update_only << :item_deposit_action_id
    end
    # An upsert, so that concurrent deposits of the same version (e.g., a double submit) can't violate the unique index.
    upsert(attributes, unique_by: %i[druid version], update_only:) # rubocop:disable Rails/SkipsModelValidations
  end

  # Called when an error of a tracked object is retried (a Process in error, or staging), so that the Deposit has
  # left In Error and any Multi-Item Deposit it belongs to has unsettled, until the next poll finds otherwise.
  # @param druid [String]
  def self.retried!(druid:)
    tracked_deposits = where(druid:)
    tracked_deposits.update_all(in_error: false, retried_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    item_deposit_actions = ItemDepositAction.where(id: tracked_deposits.select(:item_deposit_action_id))
    MultiItemDepositAction.unsettle!(item_deposit_actions.select(:multi_item_deposit_action_id))
  end

  # @return [Boolean] whether an error was retried within RETRY_GRACE_PERIOD
  def recently_retried?
    retried_at.present? && retried_at.after?(RETRY_GRACE_PERIOD.ago)
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
end
