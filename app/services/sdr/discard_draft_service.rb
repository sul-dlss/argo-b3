# frozen_string_literal: true

module Sdr
  # Discards the draft of an object: discards its open version, then deletes its mutable Content and staged files.
  class DiscardDraftService
    # Raised when the mutable Content is staging or discovering.
    class ContentBusyError < StandardError; end
    # Raised when the version is closed, is the first version, or SDR cannot discard it.
    class NotDiscardableError < StandardError; end

    def self.call(...)
      new(...).call
    end

    # SDR does not discard a first version.
    # @param version [Integer] the object's version
    # @param version_service [Sdr::VersionService] the object's version service
    # @return [Boolean] true if the draft can be discarded
    def self.discardable?(version:, version_service:)
      return false if version == 1

      version_service.open? && version_service.discardable?
    end

    # @param cocina_object [Cocina::Models::DROWithMetadata] the object, at the open version
    # @param version_service [Sdr::VersionService] the object's version service (defaults to a new one)
    def initialize(cocina_object:, version_service: nil)
      @cocina_object = cocina_object
      @version_service = version_service
    end

    # @raise [ContentBusyError] if the mutable Content is staging or discovering
    # @raise [NotDiscardableError] if the draft cannot be discarded
    # @raise [Sdr::Repository::Error] if discarding fails
    def call
      raise ContentBusyError, 'Files are being staged or discovered' if mutable_content&.staging_or_discovering?
      raise NotDiscardableError, 'Draft cannot be discarded' unless discardable?

      version_service.discard
      # Staged files belong only to the open version, so all of the object's staged files are deleted.
      Content.delete_mutable_and_staged_files(druid:)
    end

    # @return [Boolean] true if the draft can be discarded
    def discardable?
      self.class.discardable?(version: cocina_object.version, version_service:)
    end

    private

    attr_reader :cocina_object

    def druid
      cocina_object.externalIdentifier
    end

    def version_service
      @version_service ||= Sdr::VersionService.new(druid:)
    end

    def mutable_content
      @mutable_content ||= Content.mutable_for(cocina_object)
    end
  end
end
