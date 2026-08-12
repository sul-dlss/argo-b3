# frozen_string_literal: true

module BulkActions
  # Job to manage release tags
  class ManageReleaseJob < DruidsJob
    def perform(bulk_action:, druids:, to:, release:, what: 'self')
      @release_to = to
      @what = what
      @release = release
      super
    end

    attr_reader :release_to, :what, :release

    # Manage release for a single object
    class JobItem < BaseJobItem
      delegate :release_to, :what, :release, :bulk_action, to: :job

      def perform
        return unless check_update_ability?

        unless Sdr::WorkflowService.published?(druid:)
          return failure!(message: 'Object has never been published and cannot be released')
        end

        Sdr::Repository.create_release_tag(druid:, user_name: user_id, release_target: release_to,
                                           release:, release_what: what, lane_id: 'low')

        success!(message: 'Workflow creation successful')
      end
    end
  end
end
