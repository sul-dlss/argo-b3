# frozen_string_literal: true

module Sdr
  # Service for purging objects from SDR, then deleting their mutable Contents and staged files.
  class PurgeService
    def self.purgeable?(...)
      new(...).purgeable?
    end

    def self.purge(druid:, user_name:)
      new(druid:).purge(user_name:)
    end

    # A subclass of Sdr::Repository::Error, so callers can handle any SDR update failure together.
    class Error < Sdr::Repository::Error; end
    # Raised when an object cannot be purged.
    class CannotPurgeError < Error; end
    # Raised when a Content for the object is staging or discovering.
    class ContentBusyError < Error; end

    # @param druid [String] the druid of the object
    # @param version [Integer, nil] the object's version, if known
    def initialize(druid:, version: nil)
      @druid = druid
      @version = version
    end

    # A later version means the object was accessioned, so this skips the milestone lookup.
    # @return [Boolean] true if object can be purged
    def purgeable?
      return false if version && version > 1

      !Sdr::WorkflowService.submitted?(druid:)
    end

    # @raise [CannotPurgeError] if the object has been submitted
    # @raise [ContentBusyError] if a Content for the object is staging or discovering
    # @raise [Error] if purging fails
    def purge(user_name:)
      raise CannotPurgeError, 'Cannot purge an object after it is submitted' unless purgeable?
      raise ContentBusyError, 'Files are being staged or discovered' if content_busy?

      Dor::Services::Client.object(druid).destroy(user_name:)
      Content.delete_mutable_and_staged_files(druid:)
    rescue Dor::Services::Client::Error => e
      raise Error, "Purging failed: #{e.message}"
    end

    private

    attr_reader :druid, :version

    # Staging changes the lock and immutability of a Content, so every Content for the druid is checked.
    def content_busy?
      Content.where(druid:).any?(&:staging_or_discovering?)
    end
  end
end
