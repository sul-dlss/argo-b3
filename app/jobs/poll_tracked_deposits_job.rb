# frozen_string_literal: true

# Recurring job that follows each Tracked Deposit through accessioning, notifying the depositing user when it is
# Complete, and when it goes from no Process in error for its version (in any workflow) to some. Tracking ends when
# the Deposit is Complete, or silently when its version is no longer in flight (e.g., the object was purged or the
# draft discarded). An error does not end tracking.
#
# A MID Item Deposit never notifies on its own: its Process errors are recorded the same way, and once its Tracked
# Deposits are polled, each Multi-Item Deposit that has settled since the last run notifies its owner
# (MultiItemDepositSettledNotifier), until a settled email has gone out for it.
class PollTrackedDepositsJob < ApplicationJob
  queue_as :cleanup
  # Overlapping runs (e.g., when queued behind other jobs) would notify twice.
  limits_concurrency key: 'poll_tracked_deposits', duration: 1.hour

  # Bounds the druids in each Solr titles query, which Solr's maxBooleanClauses limits.
  BATCH_SIZE = 500

  def perform
    TrackedDeposit.includes(:user).find_in_batches(batch_size: BATCH_SIZE) { |batch| poll(batch) }
    MultiItemDepositAction.awaiting_settled_email.includes(:user).find_each { |mid| settle(mid) }
  end

  private

  def poll(tracked_deposits)
    statuses = Sdr::VersionService.statuses(druids: tracked_deposits.map(&:druid).uniq)
    tracked_deposits_by_outcome = tracked_deposits.group_by do |tracked_deposit|
      outcome(tracked_deposit, status: statuses[tracked_deposit.druid])
    end
    tracked_deposits_by_outcome.delete(:abandoned)&.each { |tracked_deposit| abandon(tracked_deposit) }
    report(complete: end_complete_item_deposits(tracked_deposits_by_outcome.fetch(:complete, [])),
           in_flight: tracked_deposits_by_outcome.fetch(:in_flight, []))
  end

  # A Complete MID Item Deposit counts toward its Multi-Item Deposit's settling, rather than notifying.
  # @return [Array<TrackedDeposit>] the other Complete Deposits
  def end_complete_item_deposits(tracked_deposits)
    item_deposits, others = tracked_deposits.partition(&:item_deposit_action_id)
    item_deposits.each(&:destroy!)
    others
  end

  # An abandoned MID Item Deposit was not deposited, so it is recorded as In Error, as a Deposit start failure is,
  # rather than counting as Complete toward its Multi-Item Deposit.
  def abandon(tracked_deposit)
    tracked_deposit.transaction do
      tracked_deposit.item_deposit_action&.update!(
        deposit_errors: [I18n.t('multi_item_deposit.deposit.errors.deposit_abandoned')]
      )
      tracked_deposit.destroy!
    end
  end

  # Notifies of Complete Deposits and of Deposits whose Processes went into error.
  def report(complete:, in_flight:)
    return if complete.empty? && in_flight.empty?

    titles = titles_for(druids: (complete + in_flight).map(&:druid))
    complete.each { |tracked_deposit| notify_complete(tracked_deposit, title: title_for(tracked_deposit, titles:)) }
    in_flight.each { |tracked_deposit| check_process_errors(tracked_deposit, titles:) }
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

  # A failure to get the Processes or to notify is retried by the next run (see TrackedDeposit#process_errors_found!).
  def check_process_errors(tracked_deposit, titles:)
    workflow_errors = Sdr::WorkflowService.process_errors(druid: tracked_deposit.druid,
                                                          version: tracked_deposit.version)
    tracked_deposit.process_errors_found!(workflow_errors:, title: title_for(tracked_deposit, titles:))
  rescue StandardError => e
    Rails.logger.error(e.full_message)
    Honeybadger.notify(e, context: { druid: tracked_deposit.druid })
  end

  # Settling is recorded before notifying, so that the email can tell whether the Multi-Item Deposit has unsettled
  # since. If notifying fails, settling is undone, so the next run notifies.
  def settle(multi_item_deposit_action)
    multi_item_deposit_action.record_settling!
    return unless multi_item_deposit_action.newly_settled?

    MultiItemDepositSettledNotifier.with(record: multi_item_deposit_action, name: multi_item_deposit_action.name,
                                         error_count: item_deposits_in_error_count(multi_item_deposit_action),
                                         item_deposit_count: multi_item_deposit_action.item_deposit_actions.count)
                                   .deliver(multi_item_deposit_action.user, queue: :real_time)
  rescue StandardError => e
    undo_settling(multi_item_deposit_action)
    Rails.logger.error(e.full_message)
    Honeybadger.notify(e, context: { multi_item_deposit_action_id: multi_item_deposit_action.id })
  end

  # Unless the Notification was made, in which case the next run would notify again.
  def undo_settling(multi_item_deposit_action)
    return if multi_item_deposit_action.noticed_events.exists?(created_at: multi_item_deposit_action.settled_at..)

    multi_item_deposit_action.update_columns(settled_at: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  # A MID Item Deposit is In Error if its deposit could not be started (a Deposit start failure, which has no Tracked
  # Deposit) or its Tracked Deposit is in error.
  # @return [Integer] the number of MID Item Deposits In Error
  def item_deposits_in_error_count(multi_item_deposit_action)
    multi_item_deposit_action.item_deposit_actions.with_deposit_errors.count +
      multi_item_deposit_action.tracked_deposits.in_error.count
  end

  def title_for(tracked_deposit, titles:)
    titles[tracked_deposit.druid] || DruidSupport.bare_druid_from(tracked_deposit.druid)
  end

  # @return [Hash<String, String>] the titles, keyed by druid; objects not in Solr are omitted
  def titles_for(druids:)
    Searchers::ItemByDruid.call(druids: druids.uniq, user_scope: nil, fields: [Search::Fields::ID, Search::Fields::TITLE])
                          .to_h { |item| [item.druid, item.title] }
  end
end
