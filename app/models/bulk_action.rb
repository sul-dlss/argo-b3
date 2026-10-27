# frozen_string_literal: true

# Model for tracking a bulk action.
class BulkAction < ApplicationRecord
  belongs_to :user

  enum :status, {
    created: 'created',
    queued: 'queued',
    started: 'started',
    completed: 'completed',
    cancelling: 'cancelling',
    cancelled: 'cancelled'
  }, validate: true

  after_create :create_output_directory!
  before_destroy :remove_output_directory!

  # Statuses as shown to users, which distinguish completed bulk actions with failed druids.
  DISPLAY_STATUSES = {
    'processing' => 'Processing',
    'completed' => 'Completed',
    'completed_with_errors' => 'Completed with errors',
    'cancelling' => 'Cancelling',
    'cancelled' => 'Cancelled'
  }.freeze

  # Statuses users can filter by; cancelling bulk actions are filtered as processing.
  FILTER_STATUSES = DISPLAY_STATUSES.except('cancelling').freeze

  delegate :exports, :label, to: :bulk_action_config

  # @param filter_statuses [Array<String>] keys of FILTER_STATUSES (others are ignored)
  # @return [ActiveRecord::Relation] the bulk actions with any of the filter statuses
  def self.with_filter_statuses(filter_statuses)
    (filter_statuses & FILTER_STATUSES.keys).map { |filter_status| where_filter_status(filter_status) }
                                            .reduce(:or) || none
  end

  # @param action_types [Array<String>, nil] nil for no limit
  # @param statuses [Array<String>, nil] keys of FILTER_STATUSES; nil for no limit
  # @param submitted_since [ActiveSupport::TimeWithZone, nil] nil for no limit
  # @param user_ids [Array<String>, nil] nil for no limit
  # @return [ActiveRecord::Relation] the bulk actions that match the filters
  def self.filtered(action_types: nil, statuses: nil, submitted_since: nil, user_ids: nil)
    relation = all
    relation = relation.where(user_id: user_ids) if user_ids
    relation = relation.where(action_type: action_types) if action_types
    relation = relation.with_filter_statuses(statuses) if statuses
    relation = relation.where(created_at: submitted_since..) if submitted_since
    relation
  end

  def self.where_filter_status(filter_status)
    case filter_status
    when 'processing' then where.not(status: %w[completed cancelled])
    when 'completed' then completed.where(druid_count_fail: 0)
    when 'completed_with_errors' then completed.where(druid_count_fail: 1..)
    when 'cancelled' then cancelled
    end
  end
  private_class_method :where_filter_status

  # @return [String] the key of the bulk action's DISPLAY_STATUSES
  def display_status
    return 'cancelling' if cancelling?
    return 'cancelled' if cancelled?
    return 'processing' unless completed?

    druid_count_fail.positive? ? 'completed_with_errors' : 'completed'
  end

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

  def name
    name = "Bulk action #{id}"
    return name if description.blank?

    "#{name}: #{description}"
  end

  def cancellable?
    bulk_action_config.cancellable? && (queued? || started?)
  end

  # @return [Boolean] whether the bulk action has finished, so it can be cleared from history
  def clearable?
    completed? || cancelled?
  end

  private

  def create_output_directory!
    FileUtils.mkdir_p(output_directory) unless File.directory?(output_directory)
  end
end
