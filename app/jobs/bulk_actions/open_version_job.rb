# frozen_string_literal: true

module BulkActions
  # Job to open a new version for objects
  class OpenVersionJob < BulkActions::BulkActionJob
    def perform(bulk_action:, druids:, version_description:)
      @version_description = version_description
      super
    end

    attr_reader :version_description

    # Open a new version for single item
    class OpenVersionJobItem < BulkActions::BulkActionJobItem
      def perform
        return unless check_update_ability?

        return failure!(message: "State isn't openable") unless Sdr::VersionService.openable?(druid:)

        Sdr::VersionService.open(druid:,
                                 description: version_description,
                                 opening_user_name: bulk_action.user.sunetid)
        success!(message: 'Version successfully opened')
      end

      delegate :version_description, :bulk_action, to: :job
    end
  end
end
