# frozen_string_literal: true

# Form object for editing an Item (DRO)
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm. See README for explanation.
class EditItemForm < CocinaModels::Dro
  # Keeps the "item" param key and field names (e.g., item[title]) rather than "edit_item".
  model_name_for :item

  include PermittedParamsConcern
  include EditCocinaObjectFormConcern
  include LockFormConcern
  include DescriptionCsvFormConcern
  include EmbargoFormConcern
  include FileAccessFormConcern
  include ContentDepositFormConcern
  include CollectionFormConcern
  include CatalogRecordIdFormConcern
  include CatalogRecordIdExistsFormConcern
  include FolioCatalogLinksFormConcern

  # A refreshed description would replace the spreadsheet's description.
  validate :description_csv_file_absent_when_refreshed
  validate :description_csv_must_be_valid, if: -> { description_csv_file.present? && !catalog_link_refresh? }

  # catalog_record_id is not form-only, since changing it can move refresh and serials to another Folio catalog link.
  form_only_attributes :with_embargo, :limit_collection_by_apo, :description_csv_file, :overwrite_file_access

  private

  # A change to the access is applied to the files of the cocina object and, unless depositing, of the content.
  def around_content_save(accession:)
    overwrite = content_file_access_overwrite
    yield
    # The content has no unsaved changes, so it matches what is deposited.
    accession ? content&.destroy! : overwrite_content_file_access!(overwrite)
  ensure
    rebase_content_lock
  end
end
