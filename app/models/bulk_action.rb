# frozen_string_literal: true

# Model for tracking a bulk action.
class BulkAction < ApplicationRecord
  belongs_to :user

  enum :status, { created: 'created', queued: 'queued', started: 'started', completed: 'completed' }, validate: true

  after_create :create_output_directory!, :create_log_file!
  before_destroy :remove_output_directory!

  def bulk_action_config
    BulkActions.find_config(action_type)
  end

  def enqueue_job(**params)
    bulk_action_config.job.perform_later(bulk_action: self, **params)
    queued!
  end

  def open_log_file
    File.open(log_filepath, 'a')
  end

  def reset_druid_counts!
    update!(druid_count_success: 0, druid_count_fail: 0, druid_count_total: 0)
  end

  def remove_output_directory!
    FileUtils.rm_rf(output_directory)
  end

  def output_directory
    @output_directory ||= File.join(Settings.bulk_actions.directory, "#{action_type}_#{id}")
  end

  private

  def create_output_directory!
    FileUtils.mkdir_p(output_directory) unless File.directory?(output_directory)
  end

  def create_log_file!
    log_filepath = File.join(output_directory, 'log.txt')
    FileUtils.touch(log_filepath)
    update(log_filepath:)
  end
end
