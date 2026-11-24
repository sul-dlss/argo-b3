# frozen_string_literal: true

module Sdr
  # Replaces an object's description with one made from its FOLIO record (DSA's refresh), opening a version if needed.
  # The mutable Content, if any, moves to the refreshed object's lock, so that its unsaved changes are kept.
  class FolioRefreshService
    # Raised when the description can't be refreshed (e.g., FOLIO is unavailable or the record isn't found).
    class Error < StandardError; end

    def self.call(...)
      new(...).call
    end

    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata]
    # @param user_name [String] the sunetid of the user performing the action
    # @param version_description [String] the description of the version, if one is opened
    # @param replace_open_version_description [Boolean] true to also give an already open version this description,
    #   once the refresh succeeds
    # @param version_service [Sdr::VersionService, nil] shared with the caller, since each status lookup calls DSA
    def initialize(cocina_object:, user_name:, version_description:, replace_open_version_description: false,
                   version_service: nil)
      @cocina_object = cocina_object
      @user_name = user_name
      @version_description = version_description
      @replace_open_version_description = replace_open_version_description
      @version_service = version_service
    end

    # @raise [Error] if DSA can't refresh the description, or opening or describing the version fails
    # @return [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata] the refreshed object
    def call
      # Found before opening a version changes the lock.
      content = Content.mutable_for(cocina_object)
      opened = open_version_if_closed!
      refresh!
      refreshed = find_moving_content(content)
      return refreshed if opened || !replace_open_version_description

      update_version_description!
      find_moving_content(content)
    rescue Sdr::VersionService::Error, Sdr::Repository::Error => e
      raise Error, e.message
    end

    # @return [Boolean] true if calling opened a version
    def opened_version?
      @opened_version
    end

    private

    attr_reader :cocina_object, :user_name, :version_description, :replace_open_version_description

    def druid
      cocina_object.externalIdentifier
    end

    def version_service
      @version_service ||= Sdr::VersionService.new(druid:)
    end

    # Each update changes the lock, so the mutable Content moves after each one, keeping its unsaved changes if a
    # later step fails.
    def find_moving_content(content)
      Sdr::Repository.find(druid:).tap { |refreshed| content&.update!(lock: refreshed.lock) }
    end

    def open_version_if_closed!
      @opened_version = !version_service.open?
      version_service.open(description: version_description, opening_user_name: user_name) if @opened_version
      @opened_version
    end

    def refresh!
      Dor::Services::Client.object(druid).refresh_descriptive_metadata_from_ils(user_name:)
    rescue Dor::Services::Client::Error => e
      raise Error, "Refreshing from FOLIO failed: #{e.message}"
    end

    # An unchanged description is not updated, so that no event is recorded for it.
    def update_version_description!
      return if version_description.blank? || version_description == version_service.version_description

      version_service.update_description(description: version_description, user_name:)
    end
  end
end
