# frozen_string_literal: true

module BulkActions
  # Super class for bulk jobs
  class BulkActionJob < ApplicationJob
    include ActionPolicy::Behaviour

    attr_reader :bulk_action, :druids

    # @param [BulkAction] bulk_action BulkAction object
    # @param [Array<String>] druids Array of druid strings
    # @param [Hash] params additional parameters
    def perform(bulk_action:, druids:, **params) # rubocop:disable Metrics/AbcSize
      @bulk_action = bulk_action
      @druids = druids
      Honeybadger.context(bulk_action: bulk_action.id, druids:, params:)

      bulk_action.reset_druid_counts!

      bulk_action.update(status: 'Processing')

      log("Starting #{self.class} for BulkAction #{bulk_action.id}")
      update_druid_count!

      perform_bulk_action

      log("Finished #{self.class} for BulkAction #{bulk_action.id}")
      bulk_action.completed!
    ensure
      export_file&.close
      log_file&.close
    end

    # Invokes a bulk action item for each druid
    # Each bulk action job class should implement a nested class called BulkActionItem
    # that is a subclass of BulkActionItem.
    def perform_bulk_action
      druids.each_with_index do |druid, index|
        perform_item_class.new(druid:, index:, job: self).perform
      rescue StandardError => e
        failure!(druid:, message: "Failed #{e.class} #{e.message}")
        Honeybadger.notify(e)
      end
    end

    def update_druid_count!
      bulk_action.update(druid_count_total: druid_count)
    end

    def user
      bulk_action.user.to_s
    end

    def log(message)
      log_file.puts("#{Time.zone.now} #{message}")
    end

    def druid_count
      druids.length
    end

    def close_version?
      # close version if "true" or true
      # Note that not every job provides or uses this parameter.
      ActiveModel::Type::Boolean.new.cast(params[:close_version])
    end

    def perform_item_class
      # For example, the bulk action item for AddWorkflowJob is AddWorkflowJob::AddWorkflowJobItem
      "#{self.class}::#{self.class.name.split('::').last.sub('Job', 'JobItem')}".constantize
    end

    # Open file to use for export output, if any.
    # By default, there is no export file.
    # It will be closed automatically when the job ends and available to BulkActionItem.
    # For example: @export_file ||= CSV.open(csv_download_path, 'w', write_headers: true, headers: HEADERS)
    def export_file
      @export_file ||= nil
    end

    def success!(druid:, message: nil)
      bulk_action.increment(:druid_count_success)
      log("#{message} for #{druid}") if message
    end

    def failure!(druid:, message:)
      bulk_action.increment(:druid_count_fail)
      log("#{message} for #{druid}")
    end

    private

    def log_file
      @log_file ||= bulk_action.open_log_file
    end
  end
end
