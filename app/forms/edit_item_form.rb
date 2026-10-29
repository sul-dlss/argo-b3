# frozen_string_literal: true

# Form object for editing an Item (DRO)
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm. See README for explanation.
class EditItemForm < CocinaModels::Dro
  # Keeps the "item" param key and field names (e.g., item[title]) rather than "edit_item".
  model_name_for :item

  include PermittedParamsConcern
  include VersionDescriptionConcern
  include DescriptionCsvFormConcern
  include EmbargoFormConcern
  include CollectionFormConcern
  include CatalogRecordIdFormConcern
  include CatalogRecordIdExistsFormConcern
  include FolioCatalogLinksFormConcern

  # Prefilled with the open version's description.
  validates :version_description, presence: true

  # The lock of the Cocina object when the edit page was loaded, submitted back to detect that the object
  # was changed by someone else in the meantime. It is not part of the Cocina object.
  attribute :lock, :string

  # A refreshed description would replace the spreadsheet's description.
  validate :description_csv_file_absent_when_refreshed
  validate :description_csv_must_be_valid, if: -> { description_csv_file.present? && !catalog_link_refresh? }

  # Only depositing requires the structure to be valid for the content type.
  validate :structure_valid_for_content_type, on: :deposit
  # Depositing deposits the structure as last staged, so it would discard unsaved changes.
  validate :content_is_saved, on: :deposit

  # The object's mutable Content, if any; not an attribute so that setting it does not make the form dirty.
  attr_accessor :content

  # Attributes of the form that are not part of the Cocina object, so changing only them is not a change to save.
  # catalog_record_id is not one, since changing it can move refresh and serials to another Folio catalog link.
  FORM_ONLY_ATTRIBUTES = %w[version_description lock with_embargo limit_collection_by_apo
                            description_csv_file].freeze

  # Before saving, opens a new version if the version
  # is closed and there is something to save or deposit; otherwise updates the open version's description if changed.
  # @param [String] user_name the sunetid of the user performing the action
  # @param [Boolean] accession whether to start accessioning after saving
  # @raise [ActiveModel::ValidationError] if the form is invalid
  def save!(user_name:, accession: false)
    validate!
    prepare_version!(user_name:, open_version: changed? || accession)
    super(user_name:, accession:, workflow_context: content&.workflow_context || {})
    # The content has no unsaved changes, so it matches what is deposited.
    content&.destroy! if accession
  ensure
    rebase_content_lock
  end

  def changed?
    (changed - FORM_ONLY_ATTRIBUTES).any? || tracked_associations_changed?
  end

  private

  # Keeps the content on the object's current lock, so that editing continues on it.
  def rebase_content_lock
    content.update!(lock: previous_cocina_object.lock) if content&.persisted?
  end

  # Depositing deposits the cocina structure, not the mutable Content, so the immutable Content is validated
  # against the object as edited (since the form may change its content type and access).
  def structure_valid_for_content_type
    immutable_content = Contents::Builder.find_or_create(cocina_object: previous_cocina_object)
    return if Contents::Validator.call(content: immutable_content, cocina_object: mutated_cocina_object).valid?

    errors.add(:content, I18n.t('edit.items.fields.content.validations.invalid'))
  end

  def content_is_saved
    return unless Contents::UnsavedChanges.call(content:, cocina_object: previous_cocina_object)

    errors.add(:content, I18n.t('edit.items.fields.content.validations.unsaved'))
  end

  def description_csv_file_absent_when_refreshed
    return unless description_csv_file.present? && catalog_link_refresh?

    errors.add(:description_csv_file, I18n.t('edit.items.fields.description_csv_file.validations.refreshed'))
  end

  def model_attrs_for(cocina_object)
    super.then do |attrs|
      attrs.merge(lock: cocina_object.lock, with_embargo: attrs[:embargo_release_date].present?)
    end
  end
end
