# frozen_string_literal: true

module Sdr
  # Deposits the draft of an object as last staged: starts accessioning, then deletes its mutable Content.
  class DepositDraftService
    # Superclass of the reasons the draft cannot be deposited.
    class Error < StandardError; end
    # Raised when the mutable Content is staging or discovering.
    class ContentBusyError < Error; end
    # Raised when the version is not open or cannot be closed.
    class NotDepositableError < Error; end
    # Raised when the mutable Content has unsaved changes, which depositing would discard.
    class UnsavedChangesError < Error; end
    # Raised when the content is not valid for the object's content type.
    class InvalidContentError < Error; end

    def self.call(...)
      new(...).call
    end

    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata,
    #   Cocina::Models::AdminPolicyWithMetadata] the object, at the open version
    # @param user_name [String] the sunetid of the user performing the action
    # @param lane_id [String] the lane for assembly / accessioning
    # @param version_description [String, nil] a new description for the open version, set once the draft is found
    #   depositable; nil keeps the current description
    def initialize(cocina_object:, user_name:, lane_id: 'high', version_description: nil)
      @cocina_object = cocina_object
      @user_name = user_name
      @lane_id = lane_id
      @version_description = version_description
    end

    # @raise [ContentBusyError] if the mutable Content is staging or discovering
    # @raise [NotDepositableError] if the version is not open or cannot be closed
    # @raise [UnsavedChangesError] if the mutable Content has unsaved changes
    # @raise [InvalidContentError] if the content is not valid for the content type
    # @raise [Sdr::Repository::Error] if updating the version description or starting accessioning fails
    # @return [String, nil] the name of the assembly workflow started, or nil if the version was closed
    def call
      check_depositable!
      check_content! if CocinaSupport.object_type_with_content?(cocina_object)
      # Only after the checks, so that a draft that can't be deposited keeps its description.
      update_version_description!

      context = mutable_content&.workflow_context(content_type: cocina_object.type) || {}
      Sdr::Repository.accession(cocina_object:, user_name:, lane_id:, context:).tap do
        # The mutable Content has no unsaved changes, so it matches what is deposited.
        mutable_content&.destroy!
      end
    end

    private

    attr_reader :cocina_object, :user_name, :lane_id, :version_description

    def check_depositable!
      raise ContentBusyError, I18n.t('errors.content_busy') if mutable_content&.busy?
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

    # A blank or unchanged description leaves the open version's description as it is.
    def update_version_description!
      return if version_description.blank? || version_description == version_service.version_description

      version_service.update_description(description: version_description, user_name:)
    end

    def version_service
      @version_service ||= Sdr::VersionService.new(druid: cocina_object.externalIdentifier)
    end

    def mutable_content
      @mutable_content ||= Content.mutable_for(cocina_object)
    end
  end
end
