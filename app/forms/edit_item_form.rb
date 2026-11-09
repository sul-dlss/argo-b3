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
  include FileAccessFormConcern
  include ContentDepositFormConcern
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

  # Attributes of the form that are not part of the Cocina object, so changing only them is not a change to save.
  # catalog_record_id is not one, since changing it can move refresh and serials to another Folio catalog link.
  FORM_ONLY_ATTRIBUTES = %w[version_description lock with_embargo limit_collection_by_apo
                            description_csv_file overwrite_file_access].freeze

  # Before saving, opens a new version if the version
  # is closed and there is something to save or deposit; otherwise updates the open version's description if changed.
  # A change to the access is applied to the files of the cocina object and, unless depositing, of the content.
  # @param [String] user_name the sunetid of the user performing the action
  # @param [Boolean] accession whether to start accessioning after saving
  # @raise [ActiveModel::ValidationError] if the form is invalid
  def save!(user_name:, accession: false)
    validate!
    prepare_version!(user_name:, open_version: changed? || accession)
    overwrite = content_file_access_overwrite
    super(user_name:, accession:, workflow_context: content&.workflow_context(content_type:) || {})
    # The content has no unsaved changes, so it matches what is deposited.
    accession ? content&.destroy! : overwrite_content_file_access!(overwrite)
  ensure
    rebase_content_lock
  end

  def changed?
    (changed - FORM_ONLY_ATTRIBUTES).any? || tracked_associations_changed?
  end

  private

  def description_csv_file_absent_when_refreshed
    return unless description_csv_file.present? && catalog_link_refresh?

    errors.add(:description_csv_file, I18n.t('edit.items.fields.description_csv_file.validations.refreshed'))
  end

  def model_attrs_for(cocina_object)
    super.merge(lock: cocina_object.lock)
  end
end
