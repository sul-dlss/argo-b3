# frozen_string_literal: true

# A group of Tracked Deposits that settles when every one of them is Complete (tracking has ended) or in error, e.g.,
# a Multi-Item Deposit's MID Item Deposits. The including model has `tracked_deposits` and a `settled_at` column,
# which records when it last settled and is nil while it is unsettled.
module Settleable
  extend ActiveSupport::Concern

  class_methods do
    # Marks the records as unsettled, e.g., when an error of one of their Tracked Deposits is retried.
    # @param ids [Array<Integer>, ActiveRecord::Relation] the ids of the records
    def unsettle!(ids)
      where(id: ids).where.not(settled_at: nil).update_all(settled_at: nil) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  # Records whether it is settled: no Tracked Deposit is still in flight without an error.
  # After this, `newly_settled?` says whether it has settled since it was last recorded.
  # The row is locked while checking and recording, so that a concurrent unsettle! (a retry) waits and then
  # unsettles what this records, rather than being overwritten by it.
  def record_settling!
    with_lock do
      if tracked_deposits.not_in_error.exists?
        update!(settled_at: nil) if settled_at
      elsif settled_at.nil?
        update!(settled_at: Time.current)
      end
    end
  end

  # @return [Boolean] whether the last record_settling! recorded a new settling
  def newly_settled?
    saved_change_to_settled_at? && settled_at.present?
  end
end
