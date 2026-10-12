# frozen_string_literal: true

# Form object for editing an Item (DRO)
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm. See README for explanation.
class EditItemForm < CocinaModels::Dro
  # Keeps the "item" param key and field names (e.g., item[title]) rather than "edit_item".
  model_name_for :item

  include PermittedParamsConcern

  # The description of the version being saved: used when saving opens a new version, and otherwise
  # prefilled with the open version's description. It is not part of the Cocina object.
  attribute :version_description, :string
  validates :version_description, presence: true

  # The lock of the Cocina object when the edit page was loaded, submitted back to detect that the object
  # was changed by someone else in the meantime. It is not part of the Cocina object.
  attribute :lock, :string

  include EmbargoFormConcern
  include CollectionFormConcern

  # Attributes of the form that are not part of the Cocina object, so changing only them is not a change to save.
  # with_embargo and limit_collection_by_apo only control the form; a change to the embargo is in the embargo
  # attributes.
  FORM_ONLY_ATTRIBUTES = %w[version_description lock with_embargo limit_collection_by_apo].freeze

  # Before saving (and optionally accessioning), opens a new version if the version is closed and there is
  # something to save or deposit; otherwise updates the description of the open version if it changed.
  # @param [String] user_name the sunetid of the user performing the action
  # @param [Boolean] accession whether to start accessioning after saving
  # @raise [ActiveModel::ValidationError] if the form is invalid
  def save!(user_name:, accession: false)
    validate!
    prepare_version!(user_name:, accession:)
    super
  end

  def changed?
    (changed - FORM_ONLY_ATTRIBUTES).any? || tracked_associations_changed?
  end

  private

  def prepare_version!(user_name:, accession:)
    if version_service.open?
      # Opening a version sets its description, so only the description of an already open version is updated.
      update_version_description!(user_name:) if version_description != version_service.version_description
    elsif changed? || accession
      open_version!(user_name:)
    end
  end

  def open_version!(user_name:)
    opened_cocina_object = Sdr::VersionService.open(druid:, description: version_description,
                                                    opening_user_name: user_name)
    # Rebase on the opened cocina object so that saving does not report a version mismatch.
    refresh_cocina_object(opened_cocina_object)
  end

  def update_version_description!(user_name:)
    version_service.update_description(description: version_description, user_name:)
  end

  def version_service
    @version_service ||= Sdr::VersionService.new(druid:)
  end

  def model_attrs_for(cocina_object)
    super.then { |attrs| attrs.merge(lock: cocina_object.lock, with_embargo: attrs[:embargo_release_date].present?) }
  end
end
