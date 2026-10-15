# frozen_string_literal: true

# Form object for editing an Item (DRO)
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm. See README for explanation.
class EditItemForm < CocinaModels::Dro
  # Keeps the "item" param key and field names (e.g., item[title]) rather than "edit_item".
  model_name_for :item

  include PermittedParamsConcern
  include VersionDescriptionConcern

  # Prefilled with the open version's description.
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
    prepare_version!(user_name:, open_version: changed? || accession)
    super
  end

  def changed?
    (changed - FORM_ONLY_ATTRIBUTES).any? || tracked_associations_changed?
  end

  private

  def model_attrs_for(cocina_object)
    super.then { |attrs| attrs.merge(lock: cocina_object.lock, with_embargo: attrs[:embargo_release_date].present?) }
  end
end
