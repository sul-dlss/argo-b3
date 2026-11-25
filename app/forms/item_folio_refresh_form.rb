# frozen_string_literal: true

# Form for refreshing an Item's description from its FOLIO record, then depositing or saving as a draft.
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm.
class ItemFolioRefreshForm < CocinaModels::Dro
  model_name_for :folio_refresh

  include ContentDepositFormConcern
  include FolioRefreshFormConcern

  # A background job may change the lock or structure of a busy Content, so refreshing is refused.
  def content_busy?
    content&.busy?
  end
end
