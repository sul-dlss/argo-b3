# frozen_string_literal: true

# Form object for an additional FOLIO Instance HRID on an item, beyond the one that is refreshed.
class AdditionalCatalogRecordIdForm < ApplicationForm
  include CatalogRecordIdFormConcern
  include CatalogRecordIdExistsFormConcern
end
