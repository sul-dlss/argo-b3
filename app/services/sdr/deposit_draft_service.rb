# frozen_string_literal: true

module Sdr
  # Deposits the draft of an object as last staged: starts accessioning, then deletes its mutable Content.
  class DepositDraftService
    # Raised when the mutable Content is staging or discovering.
    class ContentBusyError < StandardError; end
    # Raised when the version is not open or cannot be closed.
    class NotDepositableError < StandardError; end
    # Raised when the mutable Content has unsaved changes, which depositing would discard.
    class UnsavedChangesError < StandardError; end
    # Raised when the content is not valid for the object's content type.
    class InvalidContentError < StandardError; end

    def self.call(...)
      new(...).call
    end

    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata,
    #   Cocina::Models::AdminPolicyWithMetadata] the object, at the open version
    # @param user_name [String] the sunetid of the user performing the action
    def initialize(cocina_object:, user_name:)
      @cocina_object = cocina_object
      @user_name = user_name
    end

    # @raise [ContentBusyError] if the mutable Content is staging or discovering
    # @raise [NotDepositableError] if the version is not open or cannot be closed
    # @raise [UnsavedChangesError] if the mutable Content has unsaved changes
    # @raise [InvalidContentError] if the content is not valid for the content type
    # @raise [Sdr::Repository::Error] if starting accessioning fails
    def call
      check_depositable!
      check_content! if CocinaSupport.object_type_with_content?(cocina_object)

      Sdr::Repository.accession(cocina_object:, user_name:, context: mutable_content&.workflow_context || {})
      # The mutable Content has no unsaved changes, so it matches what is deposited.
      mutable_content&.destroy!
    end

    private

    attr_reader :cocina_object, :user_name

    def check_depositable!
      raise ContentBusyError, 'Files are being staged or discovered' if mutable_content&.staging_or_discovering?
      raise NotDepositableError, 'Draft cannot be deposited' unless version_service.open? && version_service.closeable?
    end

    def check_content!
      if Contents::UnsavedChanges.call(content: mutable_content, cocina_object:)
        raise UnsavedChangesError, 'Files have unsaved changes'
      end

      immutable_content = Contents::Builder.find_or_create(cocina_object:)
      return if Contents::Validator.call(content: immutable_content, cocina_object:).valid?

      raise InvalidContentError, 'Content is not valid for the content type'
    end

    def version_service
      @version_service ||= Sdr::VersionService.new(druid: cocina_object.externalIdentifier)
    end

    def mutable_content
      @mutable_content ||= Content.mutable_for(cocina_object)
    end
  end
end
