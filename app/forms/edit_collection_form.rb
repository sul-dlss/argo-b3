# frozen_string_literal: true

# Form object for editing and depositing a Collection
# Note that this is a subclass of CocinaModels::Collection, not ApplicationForm. See README for explanation.
class EditCollectionForm < CocinaModels::Collection
  # Keeps the "collection" param key and field names (e.g., collection[access_view]) rather than "edit_collection".
  model_name_for :collection

  include PermittedParamsConcern
  include VersionDescriptionConcern
  include LockFormConcern
  include DescriptionCsvFormConcern
  include CatalogRecordIdFormConcern
  include CatalogRecordIdExistsFormConcern
  include FolioCatalogLinksFormConcern
  include SelectableApoFormConcern

  # Not permitted as params, since the collection form has no fields for them.
  # The description is changed only by an uploaded description spreadsheet.
  # @return [Array<Symbol>]
  def self.immutable_attributes
    %i[source_id description_hash tags catalog_link_part_label catalog_link_sort_key]
  end

  # Prefilled with the open version's description.
  validates :version_description, presence: true

  validate :description_csv_file_absent_when_refreshed
  validate :description_csv_must_be_valid, if: -> { description_csv_file.present? && !catalog_link_refresh? }

  # Attributes of the form that are not part of the Cocina object, so changing only them is not a change to save.
  FORM_ONLY_ATTRIBUTES = %w[version_description lock retrieved_title description_csv_file].freeze

  # Opens a new version if the version is closed; otherwise updates the open version's description if changed.
  # Then saves any changes and starts accessioning, since a collection cannot be saved as a draft.
  # @param [String] user_name the sunetid of the user performing the action
  # @raise [ActiveModel::ValidationError] if the form is invalid
  def save!(user_name:)
    validate!
    prepare_version!(user_name:, open_version: true)
    super(user_name:, accession: true)
  end

  def changed?
    (changed - FORM_ONLY_ATTRIBUTES).any? || tracked_associations_changed?
  end
end
