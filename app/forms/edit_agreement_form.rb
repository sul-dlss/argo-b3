# frozen_string_literal: true

# Form object for editing an Agreement (a DRO with the agreement content type)
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm. See README for explanation.
class EditAgreementForm < CocinaModels::Dro
  # Keeps the "agreement" param key and field names (e.g., agreement[title]) rather than "edit_agreement".
  model_name_for :agreement

  include PermittedParamsConcern
  include TitleFormConcern
  include VersionDescriptionConcern
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

  # Prefilled with the open version's description.
  validates :version_description, presence: true

  # Attributes of the form that are not part of the Cocina object, so changing only them is not a change to save.
  FORM_ONLY_ATTRIBUTES = %w[version_description lock].freeze

  # Before saving, opens a new version if the version
  # is closed and there is something to save or deposit; otherwise updates the open version's description if changed.
  # @param [String] user_name the sunetid of the user performing the action
  # @param [Boolean] accession whether to start accessioning after saving
  # @raise [ActiveModel::ValidationError] if the form is invalid
  def save!(user_name:, accession: false)
    validate!
    prepare_version!(user_name:, open_version: changed? || accession)
    super(user_name:, accession:, workflow_context: content&.workflow_context(content_type:) || {})
    # The content has no unsaved changes, so it matches what is deposited.
    content&.destroy! if accession
  ensure
    rebase_content_lock
  end

  def changed?
    (changed - FORM_ONLY_ATTRIBUTES).any?
  end

  private

  def model_attrs_for(cocina_object)
    super.merge(title: CocinaSupport.title(cocina_object))
  end
end
