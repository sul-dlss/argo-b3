# frozen_string_literal: true

# Form object for editing and depositing an APO (Admin Policy Object)
# Note that this is a subclass of CocinaModels::AdminPolicy, not ApplicationForm. See README for explanation.
class EditApoForm < CocinaModels::AdminPolicy
  # Keeps the "apo" param key and field names (e.g., apo[title]) rather than "edit_apo".
  model_name_for :apo

  include PermittedParamsConcern
  include TitleFormConcern
  include EditCocinaObjectFormConcern
  include LockFormConcern

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

  private

  def access_location_applies?
    [access_view, access_download].include?('location-based')
  end

  def clear_access_location
    self.access_location = nil
  end

  def model_attrs_for(cocina_object)
    super.merge(title: Cocina::Models::Builders::TitleBuilder.build(cocina_object.description.title))
  end
end
