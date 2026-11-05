# frozen_string_literal: true

module Sdr
  # Service for the user (public) versions of an object.
  class UserVersionService
    # A subclass of Sdr::Repository::Error, so callers can handle any SDR update failure together.
    class Error < Sdr::Repository::Error; end

    # @param druid [String]
    # @return [Array<Dor::Services::Client::UserVersion::Version>] the user versions of the object
    # @raise [Error] if retrieving the user versions fails
    def self.inventory(druid:)
      Dor::Services::Client.object(druid).user_version.inventory
    rescue Dor::Services::Client::Error => e
      raise Error, "Retrieving user versions failed: #{e.message}"
    end

    # @param druid [String]
    # @param user_version [Integer] the user version to withdraw or restore
    # @param withdraw [Boolean] true to withdraw the user version, false to restore it
    # @raise [Error] if updating the user version fails
    def self.update(druid:, user_version:, withdraw:)
      Dor::Services::Client.object(druid).user_version.update(
        user_version: Dor::Services::Client::UserVersion::Version.new(userVersion: user_version, withdrawn: withdraw)
      )
    rescue Dor::Services::Client::Error => e
      raise Error, "Updating user version failed: #{e.message}"
    end
  end
end
