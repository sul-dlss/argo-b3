# frozen_string_literal: true

module BulkActions
  # Job to manage release tags
  class ManageReleaseJob < BulkActionJob
    def perform(bulk_action:, druids:, to:, release:, what: 'self')
      @release_to = to
      @who = who
      @what = what
      @release = release
      super
    end

    attr_reader :release_to, :who, :what, :release

    # Manage release for a single object
    class ManageReleaseJobItem < BulkActionJobItem
      delegate :release_to, :what, :release, :bulk_action, to: :job

      def perform
        return unless check_update_ability?

        unless Sdr::WorkflowService.published?(druid:)
          return failure!(message: 'Object has never been published and cannot be released')
        end

        object_client.release_tags.create(tag: new_tag)

        success!(message: 'Workflow creation successful')
      end

      def object_client
        @object_client ||= Dor::Services::Client.object(druid)
      end

      def new_tag
        Dor::Services::Client::ReleaseTag.new(
          to: release_to,
          who: bulk_action.user.sunetid,
          what:,
          release:,
          date: DateTime.now.utc.iso8601
        )
      end
    end
  end
end
