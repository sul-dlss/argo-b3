# frozen_string_literal: true

# Model for tracking a bulk action.
class BulkAction < ApplicationRecord
  belongs_to :user

  enum :status, { created: 'created', queued: 'queued', started: 'started', completed: 'completed' }, validate: true

  after_create :create_output_directory!
  before_destroy :remove_output_directory!

  delegate :export_filename, :label, to: :bulk_action_config

  def bulk_action_config
    @bulk_action_config ||= BulkActions.find_config(action_type)
  end

  def enqueue_job(**params)
    bulk_action_config.job.perform_later(bulk_action: self, **params)
    queued!
  end

  def log_filename
    'log.txt'
  end

  def log_filepath
    @log_filepath ||= filepath_for(filename: log_filename)
  end

  def log_file?
    File.exist?(log_filepath)
  end

  def export_file?
    export_filename.present? && File.exist?(export_filepath)
  end

  def export_filepath
    @export_filepath ||= filepath_for(filename: export_filename)
  end

  def export_label
    bulk_action_config.export_label || export_filename
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

  def filepath_for(filename:)
    return if filename.nil?

    File.join(output_directory, filename)
  end

  private

  def create_output_directory!
    FileUtils.mkdir_p(output_directory) unless File.directory?(output_directory)
  end
end
