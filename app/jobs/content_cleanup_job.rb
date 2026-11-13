# frozen_string_literal: true

# Job that deletes Contents whose lock is no longer the cocina object's current lock.
# Since Contents are always looked up by druid and current lock, such Contents will never be used again.
# Deleting a Content deletes its file sets, files, and binaries, and purges files attached via Active Storage.
# Files at other locations (e.g., staging, mounts) are not deleted.
class ContentCleanupJob < ApplicationJob
  queue_as :cleanup

  # Contents created more recently than this are not cleaned up.
  MINIMUM_AGE = 3.days

  def perform
    candidate_contents.group_by(&:druid).each do |druid, contents|
      current_lock = current_lock_for(druid:)
      contents.reject { |content| content.lock == current_lock }.each(&:destroy!)
    rescue StandardError => e
      Rails.logger.error(e.full_message)
      Honeybadger.notify(e, context: { druid: })
    end
  end

  private

  # Busy Contents are skipped, since their lock may be changing, as are failed stagings, whose files weren't staged.
  def candidate_contents
    Content.not_busy.where(created_at: ...MINIMUM_AGE.ago, staging_state: 'staging_not_in_progress')
  end

  # @return [String, nil] the current lock or nil if the object no longer exists
  def current_lock_for(druid:)
    Sdr::Repository.lock(druid:)
  rescue Sdr::Repository::NotFoundResponse
    nil
  end
end
