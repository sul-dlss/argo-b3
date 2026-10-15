# frozen_string_literal: true

module Sdr
  # Encapsulates all version-related functionality
  class VersionService
    # A subclass of Sdr::Repository::Error, so callers can handle any SDR update failure together.
    class Error < Sdr::Repository::Error; end

    class << self
      # @returns [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina object with updated version # rubocop:disable Layout/LineLength
      def open(druid:, **)
        new(druid:).open(**)
      end

      def close(druid:, **)
        new(druid:).close(**)
      end

      def openable?(...)
        new(...).openable?
      end

      def open?(...)
        new(...).open?
      end

      def open_and_not_assembling?(...)
        new(...).open_and_not_assembling?
      end

      def assembling?(...)
        new(...).assembling?
      end

      def accessioning?(...)
        new(...).accessioning?
      end

      def closed?(...)
        new(...).closed?
      end

      def closeable?(...)
        new(...).closeable?
      end

      def editable?(...)
        new(...).editable?
      end

      def version(...)
        new(...).version
      end
    end

    attr_reader :druid

    delegate :open?, :openable?, :assembling?, :accessioning?, :closed?, :closeable?, :version, :version_description,
             to: :status

    def initialize(druid:)
      @druid = druid
    end

    # @raise [Error] if opening the version fails
    def open(...)
      version_client.open(...)
    rescue Dor::Services::Client::Error => e
      raise Error, "Opening version failed: #{e.message}"
    end

    # @raise [Error] if closing the version fails
    def close(...)
      version_client.close(...)
    rescue Dor::Services::Client::Error => e
      raise Error, "Closing version failed: #{e.message}"
    end

    # @raise [Error] if updating the version description fails
    def update_description(...)
      version_client.update_description(...)
    rescue Dor::Services::Client::Error => e
      raise Error, "Updating version description failed: #{e.message}"
    end

    def open_and_not_assembling?
      open? && !assembling?
    end

    # @return [Boolean] true if the object can be edited: the version is closed and can be opened, or the
    #   version is open and can still be closed (e.g., it is not being assembled or accessioned)
    def editable?
      openable? || closeable?
    end

    private

    def version_client
      @version_client ||= Dor::Services::Client.object(druid).version
    end

    def status
      @status ||= version_client.status
    end
  end
end
