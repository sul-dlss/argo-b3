# frozen_string_literal: true

# Recurring job that follows each Tracked Deposit through accessioning, notifying the depositing user when it is
# Complete. Tracking ends when the Deposit is Complete, or silently when its version is no longer in flight (e.g.,
# the object was purged or the draft discarded). An error does not end tracking.
class PollTrackedDepositsJob < ApplicationJob
  queue_as :cleanup
  # Overlapping runs (e.g., when queued behind other jobs) would notify twice.
  limits_concurrency key: 'poll_tracked_deposits', duration: 1.hour

  # Bounds the druids in each Solr titles query, which Solr's maxBooleanClauses limits.
  BATCH_SIZE = 500

  def perform
    TrackedDeposit.includes(:user).find_in_batches(batch_size: BATCH_SIZE) { |batch| poll(batch) }
  end

  private

  def poll(tracked_deposits)
    statuses = Sdr::VersionService.statuses(druids: tracked_deposits.map(&:druid).uniq)
    tracked_deposits_by_outcome = tracked_deposits.group_by do |tracked_deposit|
      outcome(tracked_deposit, status: statuses[tracked_deposit.druid])
    end
    tracked_deposits_by_outcome.fetch(:abandoned, []).each(&:destroy!)
    complete(tracked_deposits_by_outcome.fetch(:complete, []))
  end

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
      notify_complete(tracked_deposit, title: titles.fetch(tracked_deposit.druid,
                                                           DruidSupport.bare_druid_from(tracked_deposit.druid)))
    end
  end

  # Tracking ends only once the user is notified, so a failure to notify is retried by the next run.
  def notify_complete(tracked_deposit, title:)
    DepositCompleteNotifier.with(druid: tracked_deposit.druid, version: tracked_deposit.version, title:)
                           .deliver(tracked_deposit.user, queue: :real_time)
    tracked_deposit.destroy!
  rescue StandardError => e
    Rails.logger.error(e.full_message)
    Honeybadger.notify(e, context: { druid: tracked_deposit.druid })
  end

  # @return [Hash<String, String>] the titles, keyed by druid; objects not in Solr are omitted
  def titles_for(druids:)
    Searchers::ItemByDruid.call(druids:, user_scope: nil, fields: [Search::Fields::ID, Search::Fields::TITLE])
                          .to_h { |item| [item.druid, item.title] }
  end
end
