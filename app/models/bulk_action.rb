# frozen_string_literal: true

# Model for tracking a bulk action.
class BulkAction < ApplicationRecord
  belongs_to :user

  enum :status, { created: 'created', queued: 'queued', started: 'started', completed: 'completed' }, validate: true

  after_create :create_output_directory!
  before_destroy :remove_output_directory!

  delegate :exports, :label, to: :bulk_action_config

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

  # @param key [Symbol] key of the export in the bulk action config
  def export_filepath(key)
    filepath_for(filename: bulk_action_config.find_export(key).filename)
  end

  # @return [Array<BulkActions::Export>] the exports whose files have been created
  def existing_exports
    exports.select { |export| File.exist?(filepath_for(filename: export.filename)) }
  end

  # Only the log and export files may be downloaded.
  def downloadable_filename?(filename)
    filename == log_filename || exports.any? { |export| export.filename == filename }
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
