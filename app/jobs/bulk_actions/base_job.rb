# frozen_string_literal: true

module BulkActions
  # Super class for bulk jobs
  class BaseJob < ApplicationJob
    include ActionPolicy::Behaviour

    attr_reader :bulk_action, :druids

    # @param [BulkAction] bulk_action BulkAction object
    # @param [Hash] params additional parameters
    def perform(bulk_action:, **params) # rubocop:disable Metrics/AbcSize
      @bulk_action = bulk_action
      Honeybadger.context(bulk_action: bulk_action.id, params:)

      bulk_action.reset_druid_counts!

      bulk_action.update(status: 'Processing')

      log("Starting #{self.class} for BulkAction #{bulk_action.id}")
      update_druid_count!

      perform_bulk_action

      log("Finished #{self.class} for BulkAction #{bulk_action.id}")
      bulk_action.completed!
      perform_broadcast
    ensure
      export_file&.close
      log_file&.close
    end

    # Subclasses must implement.
    def perform_bulk_action
      raise NotImplementedError
    end

    def update_druid_count!
      bulk_action.update(druid_count_total: druid_count)
    end

    def user
      bulk_action.user.sunetid
    end

    def log(message)
      log_file.puts("#{Time.zone.now} #{message}")
    end

    # Subclasses must implement.
    # @return [Integer] total number of druids
    def druid_count
      raise NotImplementedError
    end

    # Subclasses may override if they support closing versions.
    def close_version?
      false
    end

    def perform_item_class
      # For example, the bulk action item for AddWorkflowJob is AddWorkflowJob::Item
      self.class.const_get('Item')
    end

    # Open file to use for export output, if any.
    # By default, there is no export file.
    # It will be closed automatically when the job ends and available to BulkActionItem.
    # For example: @export_file ||= CSV.open(csv_download_path, 'w', write_headers: true, headers: HEADERS)
    def export_file
      @export_file ||= nil
    end

    private

    def log_file
      @log_file ||= File.open(bulk_action.log_filepath, 'a')
    end

    def perform_broadcast
      component = SdrViewComponents::Elements::ToastComponent.new(title: "#{bulk_action.label} completed")
      Turbo::StreamsChannel.broadcast_append_to('notifications', bulk_action.user,
                                                target: 'toast-container',
                                                html: ApplicationController.render(component, layout: false))
    end
  end
end
