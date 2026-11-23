# frozen_string_literal: true

module Sdr
  # Starts a Goobi Redeposit: opens a version if one is not already open, then starts goobiWF for it.
  # Goobi deposits the item later, which closes the version.
  class GoobiRedepositService
    WORKFLOW_NAME = 'goobiWF'
    VERSION_DESCRIPTION = 'Redeposit with Goobi'
    COMPLETE_STATUSES = %w[completed skipped].freeze

    # Superclass of the reasons a Goobi Redeposit is not possible.
    class NotRedepositableError < StandardError; end
    # Raised when the object is not an image or book Item.
    class NotGoobiTypeError < NotRedepositableError; end
    # Raised when goobiWF was started for the open version, which Goobi has not yet deposited.
    class GoobiProcessingError < NotRedepositableError; end
    # Raised when a workflow has a process that is not complete.
    class ActiveWorkflowError < NotRedepositableError; end
    # A subclass of Sdr::Repository::Error, so callers can handle any SDR update failure together.
    class Error < Sdr::Repository::Error; end

    def self.call(...)
      new(...).call
    end

    # @param cocina_object [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy]
    # @return [Boolean] true if the object is an image or book Item
    def self.goobi_content_type?(cocina_object)
      CocinaSupport.item?(cocina_object) && Constants::GOOBI_CONTENT_TYPES.include?(cocina_object.type)
    end

    # @param version_service [Sdr::VersionService] the object's version service
    # @return [Boolean] true if the object's state allows a Goobi Redeposit
    def self.redepositable?(version_service:)
      check_redepositable!(version_service:)
      true
    rescue NotRedepositableError
      false
    end

    # A Goobi Redeposit is not possible while goobiWF has been started for the open version (Goobi has not yet
    # deposited it), or while any workflow has a process that is not complete.
    # @param version_service [Sdr::VersionService] the object's version service
    # @raise [GoobiProcessingError] if goobiWF was started for the open version
    # @raise [ActiveWorkflowError] if a workflow has a process that is not complete
    def self.check_redepositable!(version_service:)
      processes = WorkflowService.workflows_for(druid: version_service.druid).flat_map(&:processes)
      version = version_service.version
      raise GoobiProcessingError if version_service.open? && goobi_started?(processes:, version:)
      raise ActiveWorkflowError unless processes.all? { |process| COMPLETE_STATUSES.include?(process.status) }
    end

    # @param processes [Array<Dor::Services::Response::Process>] the processes of the object's workflows
    # @param version [Integer] the version
    # @return [Boolean] true if goobiWF was started for the version (for version 1, at registration)
    def self.goobi_started?(processes:, version:)
      processes.any? { |process| process.workflow_name == WORKFLOW_NAME && process.version == version }
    end

    # @param cocina_object [Cocina::Models::DROWithMetadata] the object
    # @param user_name [String] the user starting the Goobi Redeposit
    def initialize(cocina_object:, user_name:)
      @cocina_object = cocina_object
      @user_name = user_name
    end

    # @raise [NotRedepositableError] a subclass, if the object is not an image or book Item or its state does not
    #   allow a Goobi Redeposit
    # @raise [Sdr::Repository::Error] if opening the version or starting goobiWF fails
    def call
      raise NotGoobiTypeError unless self.class.goobi_content_type?(cocina_object)

      self.class.check_redepositable!(version_service:)
      Dor::Services::Client.object(druid).workflow(WORKFLOW_NAME).create(version: open_version)
    rescue Dor::Services::Client::Error => e
      raise Error, "Starting #{WORKFLOW_NAME} failed: #{e.message}"
    end

    private

    attr_reader :cocina_object, :user_name

    def druid
      cocina_object.externalIdentifier
    end

    def version_service
      @version_service ||= Sdr::VersionService.new(druid:)
    end

    # An already open version keeps its description.
    # @return [Integer] the open version
    def open_version
      return version_service.version if version_service.open?

      version_service.open(description: VERSION_DESCRIPTION, opening_user_name: user_name).version
    end
  end
end
