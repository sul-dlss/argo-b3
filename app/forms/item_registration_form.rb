# frozen_string_literal: true

# Form object for registering a single item as part of multiple item registration (DROs)
class ItemRegistrationForm < ApplicationForm
  include PermittedParamsConcern
  include CocinaModels::SourceIdConcern
  include CocinaModels::BarcodeConcern
  include CocinaModels::CatalogRecordIdConcern
  include TitleFormConcern

  validate :title_present_unless_catalog_record_id

  def empty?
    model_attributes.values.all?(&:blank?)
  end

  private

  def title_present_unless_catalog_record_id
    return if title.present? || catalog_record_id.present?

    errors.add(:title, I18n.t('edit.multiple_items.validations.title_required'))
  end
end
