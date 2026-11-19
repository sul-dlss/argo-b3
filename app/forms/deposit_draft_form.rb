# frozen_string_literal: true

# Form for depositing a Draft as last staged from the object page's status box, after describing its version.
class DepositDraftForm < ApplicationForm
  model_name_for :deposit

  # The lock of the Cocina object when the object page was loaded, submitted back with the form.
  attribute :lock, :string

  # Required in the browser; a blank one keeps the open version's description (see Sdr::DepositDraftService).
  attribute :version_description, :string

  # @param lock [String] the lock of the Cocina object as the object page loaded it
  # @param version_service [Sdr::VersionService] for the object's open version
  # @return [self] the form for the status box, prefilled with the open version's description
  def self.for_status(lock:, version_service:)
    new(lock:, version_description: version_service.version_description)
  end

  # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata,
  #   Cocina::Models::AdminPolicyWithMetadata]
  # @return [String] the warning the object type's edit form gives when the object changed since it was loaded
  def self.stale_warning(cocina_object)
    I18n.t("edit.#{edit_controller_name(cocina_object)}.edit.warnings.stale")
  end

  def self.edit_controller_name(cocina_object)
    return 'apos' if cocina_object.admin_policy?
    return 'collections' if cocina_object.collection?
    return 'agreements' if CocinaSupport.agreement?(cocina_object)

    # Items and Virtual Objects, which are edited as Items.
    'items'
  end
  private_class_method :edit_controller_name

  # The lock changes whenever the object is updated, so a different (or missing) lock means it changed since loading.
  # @param cocina_object (see .stale_warning) the current object
  def stale?(cocina_object)
    lock != cocina_object.lock
  end

  # Deposits the Draft as last staged, first updating the open version's description if it changed.
  # @param cocina_object (see .stale_warning) the current object, at the open version
  # @param user_name [String] the sunetid of the user depositing
  # @raise [Sdr::DepositDraftService::Error] if the Draft can't be deposited (see Sdr::DepositDraftService#call)
  # @raise [Sdr::Repository::Error] if updating the version description or starting accessioning fails
  def deposit!(cocina_object:, user_name:)
    Sdr::DepositDraftService.call(cocina_object:, user_name:, version_description:)
  end
end
