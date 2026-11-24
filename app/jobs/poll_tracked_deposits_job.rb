# frozen_string_literal: true

# Recurring job that follows each Tracked Deposit through accessioning, notifying the depositing user when it is
# Complete. Tracking ends when the Deposit is Complete, or silently when its version is no longer in flight (e.g.,
# the object was purged or the draft discarded). An error does not end tracking.
class PollTrackedDepositsJob < ApplicationJob
  queue_as :cleanup

  def perform
    tracked_deposits = TrackedDeposit.includes(:user).to_a
    return if tracked_deposits.empty?

    statuses = Sdr::VersionService.statuses(druids: tracked_deposits.map(&:druid).uniq)
    by_outcome = tracked_deposits.group_by do |tracked_deposit|
      outcome(tracked_deposit, status: statuses[tracked_deposit.druid])
    end
    by_outcome.fetch(:abandoned, []).each(&:destroy!)
    complete(by_outcome.fetch(:complete, []))
  end

  private

  # @return [Symbol] :complete, :abandoned (no longer in flight), or :in_flight
  def outcome(tracked_deposit, status:)
    return :abandoned if tracked_deposit.abandoned?(status)
    return :complete if tracked_deposit.complete?(status)

    :in_flight
  end

  def complete(tracked_deposits)
    return if tracked_deposits.empty?

    titles = titles_for(druids: tracked_deposits.map(&:druid))
    tracked_deposits.each do |tracked_deposit|
      druid = tracked_deposit.druid
      deliver_notification(DepositCompleteNotifier, recipient: tracked_deposit.user, druid:,
                                                    version: tracked_deposit.version,
                                                    title: titles.fetch(druid, DruidSupport.bare_druid_from(druid)))
      tracked_deposit.destroy!
    end
  end

  # @return [Hash<String, String>] the titles, keyed by druid; objects not in Solr are omitted
  def titles_for(druids:)
    Searchers::ItemByDruid.call(druids:, user_scope: nil, fields: [Search::Fields::ID, Search::Fields::TITLE])
                          .to_h { |item| [item.druid, item.title] }
  end
end
