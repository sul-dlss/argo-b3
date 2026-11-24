# frozen_string_literal: true

# A Deposit started in Argo-B3, remembered from when it starts until it is Complete, so that its outcome can be
# reported to the depositing user (see PollTrackedDepositsJob). Tracking ends by destroying the record.
class TrackedDeposit < ApplicationRecord
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
