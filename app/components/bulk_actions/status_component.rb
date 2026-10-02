# frozen_string_literal: true

module BulkActions
  # Component for rendering a bulk action's status with its icon.
  class StatusComponent < ApplicationComponent
    def initialize(bulk_action:)
      @bulk_action = bulk_action
      super()
    end

    attr_reader :bulk_action

    def label
      return 'Processing' unless bulk_action.completed?

      bulk_action.druid_count_fail.positive? ? 'Completed with errors' : 'Completed'
    end

    def icon
      return unless bulk_action.completed?

      if bulk_action.druid_count_fail.positive?
        helpers.warning_icon(classes: 'text-warning', aria: { hidden: true })
      else
        helpers.success_icon(classes: 'text-success', aria: { hidden: true })
      end
    end
  end
end
