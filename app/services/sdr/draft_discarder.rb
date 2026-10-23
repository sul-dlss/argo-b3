# frozen_string_literal: true

module Sdr
  # Discards the draft of an object: discards its open version (or purges it, for a first version),
  # then deletes its mutable Content and staged files.
  class DraftDiscarder
    # Raised when the mutable Content is staging or discovering.
    class ContentBusyError < StandardError; end
    # Raised when the version is closed or SDR cannot discard (or purge) it.
    class NotDiscardableError < StandardError; end

    def self.call(...)
      new(...).call
    end

    # @param cocina_object [Cocina::Models::DROWithMetadata] the object, at the open version
    # @param user_name [String] the sunetid of the user discarding the draft
    def initialize(cocina_object:, user_name:)
      @cocina_object = cocina_object
      @user_name = user_name
    end

    # @return [Boolean] true if the object was purged
    # @raise [ContentBusyError] if the mutable Content is staging or discovering
    # @raise [NotDiscardableError] if the draft cannot be discarded
    # @raise [Sdr::Repository::Error] if discarding or purging fails
    def call
      raise ContentBusyError, 'Files are being staged or discovered' if mutable_content&.staging_or_discovering?
      raise NotDiscardableError, 'Draft cannot be discarded' unless discardable?

      purge? ? Sdr::PurgeService.purge(druid:, user_name:) : version_service.discard
      clean_up
      purge?
    end

    private

    attr_reader :cocina_object, :user_name

    def druid
      cocina_object.externalIdentifier
    end

    def version_service
      @version_service ||= Sdr::VersionService.new(druid:)
    end

    def mutable_content
      @mutable_content ||= Content.mutable_for(cocina_object)
    end

    # SDR does not discard a first version, but an unsubmitted first version can be purged instead.
    def discardable?
      return false unless version_service.open?
      return Sdr::PurgeService.can_purge?(druid:) if purge?

      version_service.discardable?
    end

    def purge?
      cocina_object.version == 1
    end

    # The draft is already gone from SDR, so a cleanup failure is reported rather than raised.
    # Staged files belong only to the open version, so all of the object's staged files are deleted.
    def clean_up
      mutable_content&.destroy!
      StagingSupport.delete_staged_files(druid:)
    rescue StandardError => e
      Rails.logger.error(e.full_message)
      Honeybadger.notify(e, context: { druid: })
    end
  end
end
