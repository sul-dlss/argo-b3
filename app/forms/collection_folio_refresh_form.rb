# frozen_string_literal: true

# Form for refreshing a Collection's description from its FOLIO record, then depositing it.
# Note that this is a subclass of CocinaModels::Collection, not ApplicationForm.
class CollectionFolioRefreshForm < CocinaModels::Collection
  model_name_for :folio_refresh

  include EditCocinaObjectFormConcern
  include FolioRefreshFormConcern

  # A collection has no files.
  def content_busy? = false
end
