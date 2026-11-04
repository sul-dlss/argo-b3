# frozen_string_literal: true

# Form object for editing and depositing an APO (Admin Policy Object)
# Note that this is a subclass of CocinaModels::AdminPolicy, not ApplicationForm. See README for explanation.
class EditApoForm < CocinaModels::AdminPolicy
  # Keeps the "apo" param key and field names (e.g., apo[title]) rather than "edit_apo".
  model_name_for :apo

  include PermittedParamsConcern
  include TitleFormConcern
  include VersionDescriptionConcern

  # Not permitted as params, since the APO form has no fields for them.
  # The description is derived from the title.
  # @return [Array<Symbol>]
  def self.immutable_attributes
    %i[apo_druid description_hash tags]
  end

  validates :title, presence: true
  # Only a changed title replaces the title in the description, so that an unchanged structured title is retained.
  before_validation :populate_title_in_description_hash, if: -> { title_changed? && title.present? }

  # The location field is disabled (and so not submitted) when it does not apply, so it is cleared here.
  before_validation :clear_access_location, unless: :access_location_applies?

  # Prefilled with the open version's description.
  validates :version_description, presence: true

  # The lock of the Cocina object when the edit page was loaded, submitted back to detect that the object
  # was changed by someone else in the meantime. It is not part of the Cocina object.
  attribute :lock, :string

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
    super
  end

  def changed?
    (changed - FORM_ONLY_ATTRIBUTES).any?
  end

  private

  # Replaces only the title, so that the rest of the description is retained.
  def populate_title_in_description_hash
    self.description_hash = description_hash.merge(title: [{ value: title }])
  end

  def access_location_applies?
    [access_view, access_download].include?('location-based')
  end

  def clear_access_location
    self.access_location = nil
  end

  def model_attrs_for(cocina_object)
    super.merge(lock: cocina_object.lock,
                title: Cocina::Models::Builders::TitleBuilder.build(cocina_object.description.title))
  end
end
