# frozen_string_literal: true

# Form object for editing an Agreement (a DRO with the agreement content type)
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm. See README for explanation.
class EditAgreementForm < CocinaModels::Dro
  # Keeps the "agreement" param key and field names (e.g., agreement[title]) rather than "edit_agreement".
  model_name_for :agreement

  include PermittedParamsConcern
  include TitleFormConcern
  include EditCocinaObjectFormConcern
  include LockFormConcern
  include ContentDepositFormConcern

  # Only the fields of the agreement form, since an agreement's content type, governing APO (the ur APO),
  # and (dark) access are fixed, and it has none of an item's other attributes (e.g., collections).
  # @return [Array<Symbol>]
  def self.permitted_params
    %i[title source_id version_description lock]
  end

  validates :title, presence: true
  # Only a changed title replaces the title in the description, so that an unchanged structured title is retained.
  before_validation :populate_title_in_description_hash, if: -> { title_changed? && title.present? }

  private

  def around_content_save(accession:)
    yield
    # The content has no unsaved changes, so it matches what is deposited.
    content&.destroy! if accession
  ensure
    rebase_content_lock
  end

  def model_attrs_for(cocina_object)
    super.merge(title: CocinaSupport.title(cocina_object))
  end
end
