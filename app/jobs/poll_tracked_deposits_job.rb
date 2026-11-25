# frozen_string_literal: true

# Recurring job that follows each Tracked Deposit through accessioning, notifying the depositing user when it is
# Complete, and when it goes from no Process in error (in any workflow) to some. Tracking ends when the Deposit is
# Complete, or silently when its version is no longer in flight (e.g., the object was purged or the draft discarded).
# An error does not end tracking.
class PollTrackedDepositsJob < ApplicationJob
  queue_as :cleanup
  # Overlapping runs (e.g., when queued behind other jobs) would notify twice.
  limits_concurrency key: 'poll_tracked_deposits', duration: 1.hour

  # Bounds the druids in each Solr titles query, which Solr's maxBooleanClauses limits.
  BATCH_SIZE = 500

  FIELDS = [Search::Fields::ID, Search::Fields::TITLE, Search::Fields::WORKFLOW_ERRORS].freeze

  def perform
    TrackedDeposit.includes(:user).find_in_batches(batch_size: BATCH_SIZE) { |batch| poll(batch) }
  end

  private

  def poll(tracked_deposits)
    statuses = Sdr::VersionService.statuses(druids: tracked_deposits.map(&:druid).uniq)
    tracked_deposits_by_outcome = tracked_deposits.group_by do |tracked_deposit|
      outcome(tracked_deposit, status: statuses[tracked_deposit.druid])
    end
    tracked_deposits_by_outcome.delete(:abandoned)&.each(&:destroy!)
    report(complete: tracked_deposits_by_outcome.fetch(:complete, []),
           in_flight: tracked_deposits_by_outcome.fetch(:in_flight, []))
  end

  # Notifies of Complete Deposits and of Deposits whose Processes went into error.
  def report(complete:, in_flight:)
    return if complete.empty? && in_flight.empty?

    items = items_for(druids: (complete + in_flight).map(&:druid))
    complete.each { |tracked_deposit| notify_complete(tracked_deposit, title: title_for(tracked_deposit, items:)) }
    in_flight.each { |tracked_deposit| check_process_errors(tracked_deposit, items:) }
  end

  # @return [Symbol] :complete, :abandoned (no longer in flight), or :in_flight
  def outcome(tracked_deposit, status:)
    return :abandoned if tracked_deposit.abandoned?(status)
    return :complete if tracked_deposit.complete?(status)

    :in_flight
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

  # An object not in Solr is left as it was, since its Processes are unknown.
  # A failure to notify is retried by the next run (see TrackedDeposit#process_errors_found!).
  def check_process_errors(tracked_deposit, items:)
    item = items[tracked_deposit.druid]
    return unless item

    tracked_deposit.process_errors_found!(workflow_errors: Array(item.workflow_errors),
                                          title: title_for(tracked_deposit, items:))
  rescue StandardError => e
    Rails.logger.error(e.full_message)
    Honeybadger.notify(e, context: { druid: tracked_deposit.druid })
  end

  def title_for(tracked_deposit, items:)
    items[tracked_deposit.druid]&.title || DruidSupport.bare_druid_from(tracked_deposit.druid)
  end

  # @return [Hash<String, SearchResults::Item>] the objects' titles and Processes in error, keyed by druid; objects
  #   not in Solr are omitted
  def items_for(druids:)
    Searchers::ItemByDruid.call(druids: druids.uniq, user_scope: nil, fields: FIELDS).index_by(&:druid)
  end
end
