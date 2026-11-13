# frozen_string_literal: true

module BulkActions
  # Job to redeposit objects: deposits each object's draft, opening a new version first if none is open.
  class RedepositJob < DruidsJob
    # @param version_description [String] the description of opened versions, and of open versions without one
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

        if version_service.open?
          describe_open_version_if_blank!
        elsif version_service.openable?
          open_version!
        else
          return failure!(message: 'Version cannot be opened (e.g., the object is being accessioned)')
        end

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

      # The description of an open version is kept unless it is blank.
      def describe_open_version_if_blank!
        return if version_service.version_description.present?

        version_service.update_description(description: version_description, user_name: user_id)
        log("Updated version description (#{version_description})")
      end
    end
  end
end
