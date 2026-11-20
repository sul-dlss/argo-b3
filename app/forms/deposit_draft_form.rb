# frozen_string_literal: true

# Form for depositing a Draft as last staged from the object page's status box, after describing its version.
class DepositDraftForm < ApplicationForm
  model_name_for :deposit

  # Required in the browser; a blank one keeps the open version's description (see Sdr::DepositDraftService).
  attribute :version_description, :string

  # @param version_service [Sdr::VersionService] for the object's open version
  # @return [self] the form for the status box, prefilled with the open version's description
  def self.for_status(version_service:)
    new(version_description: version_service.version_description)
  end

  # Deposits the Draft as last staged, first updating the open version's description if it changed.
  # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata,
  #   Cocina::Models::AdminPolicyWithMetadata] the current object, at the open version
  # @param user_name [String] the sunetid of the user depositing
  # @raise [Sdr::DepositDraftService::Error] if the Draft can't be deposited (see Sdr::DepositDraftService#call)
  # @raise [Sdr::Repository::Error] if updating the version description or starting accessioning fails
  def deposit!(cocina_object:, user_name:)
    Sdr::DepositDraftService.call(cocina_object:, user_name:, version_description:)
  end
end
