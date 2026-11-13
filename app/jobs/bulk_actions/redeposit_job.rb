# frozen_string_literal: true

module BulkActions
  # Job to redeposit objects: deposits each object's draft, opening a new version first if none is open.
  class RedepositJob < DruidsJob
    # @param version_description [String] the description of opened versions; open versions keep their own
    def perform(bulk_action:, druids:, version_description:)
      @version_description = version_description
      super
    end

    attr_reader :version_description

    # Redeposit a single object.
    class JobItem < BaseJobItem
      delegate :version_description, to: :job

      def perform
        return unless check_update_ability?

        unless version_service.open? || version_service.openable?
          return failure!(message: 'Version cannot be opened (e.g., the object is being accessioned)')
        end

        open_version! unless version_service.open?
        deposit!(failure_prefix: 'Not deposited')
        success!(message: 'Object successfully redeposited')
      end

      private

      def version_service
        @version_service ||= Sdr::VersionService.new(druid:)
      end

      def open_version!
        version_service.open(description: version_description, opening_user_name: user_id)
        log("Opened new version (#{version_description})")
      end
    end
  end
end
