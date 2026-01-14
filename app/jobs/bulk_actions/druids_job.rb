# frozen_string_literal: true

module BulkActions
  # Superclass of bulk action jobs that take druids as input
  class DruidsJob < BaseJob
    include ActionPolicy::Behaviour

    attr_reader :bulk_action, :druids

    # @param [BulkAction] bulk_action BulkAction object
    # @param [Array<String>] druids Array of druid strings
    # @param [Hash] params additional parameters
    def perform(bulk_action:, druids:, **params)
      @druids = druids

      super
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

    def druid_count
      druids.length
    end

    def success!(druid:, message: nil)
      bulk_action.increment(:druid_count_success)
      log("#{message} for #{druid}") if message
    end

    def failure!(druid:, message:)
      bulk_action.increment(:druid_count_fail)
      log("#{message} for #{druid}")
    end
  end
end
