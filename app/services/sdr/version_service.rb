# frozen_string_literal: true

module Sdr
  # Encapsulates all version-related functionality
  class VersionService
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

    delegate :close, :open, :update_description, to: :version_client
    delegate :open?, :openable?, :assembling?, :accessioning?, :closed?, :closeable?, :version, :version_description,
             to: :status

    def initialize(druid:)
      @druid = druid
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
