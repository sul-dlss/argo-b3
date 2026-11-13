# frozen_string_literal: true

# Form object for editing and depositing a Collection
# Note that this is a subclass of CocinaModels::Collection, not ApplicationForm. See README for explanation.
class EditCollectionForm < CocinaModels::Collection
  # Keeps the "collection" param key and field names (e.g., collection[access_view]) rather than "edit_collection".
  model_name_for :collection

  include PermittedParamsConcern
  include EditCocinaObjectFormConcern
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

  validate :description_csv_file_absent_when_refreshed
  validate :description_csv_must_be_valid, if: -> { description_csv_file.present? && !catalog_link_refresh? }

  form_only_attributes :retrieved_title, :description_csv_file

  # Always accessions, since a collection cannot be saved as a draft.
  # @param [String] user_name the sunetid of the user performing the action
  # @raise [ActiveModel::ValidationError] if the form is invalid
  def save!(user_name:)
    super(user_name:, accession: true)
  end
end
